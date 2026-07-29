pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Thin REST client for the Helena AI API (see API.md in the helena-ai repo).
// v1 scope is chat only: login, history, send/receive. No WebSocket (not
// available as a QML module here) - POST /messages already returns the
// assistant's replies synchronously, which covers the interactive loop.
Singleton {
    id: root

    readonly property string baseUrl: "http://localhost:4567"
    readonly property string repoUrl: "https://github.com/wellington0dev/helena-ai.git"

    property string token: sessionAdapter.token
    property var user: null
    property var messages: []

    property bool loggingIn: false
    property string loginError: ""
    property bool loadingHistory: false
    property bool sending: false
    property string sendError: ""

    readonly property bool loggedIn: token.length > 0

    // true assim que uma checagem confirma que o servidor não responde -
    // diferente de loginError/sendError (que só populam DEPOIS de uma ação
    // do usuário), isso é checado proativamente (ver checkServer(), chamado
    // por HelenaWindow.qml ao abrir o painel) pra avisar mesmo se a pessoa só
    // abriu o chat pra olhar, sem tentar logar ou mandar nada ainda.
    property bool serverUnreachable: false

    function checkServer() {
        const xhr = new XMLHttpRequest()
        xhr.open("GET", root.baseUrl + "/health")
        xhr.timeout = 5000
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            root.serverUnreachable = (xhr.status === 0)
        }
        xhr.send()
    }

    FileView {
        id: sessionFile
        path: Quickshell.env("HOME") + "/.config/quickshell/State/helena-session.json"
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: sessionAdapter
            property string token: ""
            property string username: ""
        }
    }

    function saveSession(tok, username) {
        sessionAdapter.token = tok
        sessionAdapter.username = username
        sessionFile.writeAdapter()
    }

    onTokenChanged: {
        if (token) {
            loadHistory()
            if (!user) fetchMe()
        } else {
            messages = []
            user = null
        }
    }

    function request(method, path, body, onSuccess, onError) {
        const xhr = new XMLHttpRequest()
        xhr.open(method, root.baseUrl + path)
        xhr.setRequestHeader("Content-Type", "application/json")
        if (root.token) xhr.setRequestHeader("Authorization", "Bearer " + root.token)
        xhr.timeout = 180000
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            let data = null
            try { data = JSON.parse(xhr.responseText) } catch (e) { /* no body */ }
            if (xhr.status >= 200 && xhr.status < 300) {
                onSuccess(data)
            } else {
                if (xhr.status === 401 && root.token) root.logout()
                // status 0 = XHR nunca chegou a receber resposta HTTP nenhuma
                // (conexão recusada) - o sinal de que o servidor da Helena
                // não tá rodando em root.baseUrl, não um erro comum da API.
                const msg = xhr.status === 0
                    ? "Não consegui falar com a Helena em " + root.baseUrl + ". " +
                      "Ela ainda não tá instalada/rodando nesta máquina? " +
                      "Clone " + root.repoUrl + " e rode 'helena setup' + 'helena start' " +
                      "(ou 'helena service install' pra subir sozinha no login)."
                    : (data && data.error) || ("Erro " + xhr.status)
                onError(msg, xhr.status)
            }
        }
        xhr.send(body !== undefined ? JSON.stringify(body) : undefined)
    }

    function login(username, password) {
        loggingIn = true
        loginError = ""
        request("POST", "/auth/login", { username, password },
            (data) => {
                loggingIn = false
                user = data.user
                token = data.access_token
                saveSession(data.access_token, data.user.username)
            },
            (err) => {
                loggingIn = false
                loginError = err
            }
        )
    }

    function register(username, password) {
        loggingIn = true
        loginError = ""
        request("POST", "/auth/register", { username, password },
            (data) => {
                loggingIn = false
                user = data.user
                token = data.access_token
                saveSession(data.access_token, data.user.username)
            },
            (err) => {
                loggingIn = false
                loginError = err
            }
        )
    }

    function logout() {
        token = ""
        saveSession("", "")
    }

    function fetchMe() {
        request("GET", "/account/me", undefined,
            (data) => { user = data.user },
            (err) => { /* keep whatever we had */ }
        )
    }

    function loadHistory() {
        loadingHistory = true
        request("GET", "/messages?limit=50", undefined,
            (data) => {
                loadingHistory = false
                messages = data.messages
            },
            (err) => { loadingHistory = false }
        )
    }

    function sendMessage(content) {
        const text = content.trim()
        if (!text || sending) return

        sending = true
        sendError = ""

        const optimisticId = -Date.now()
        messages = messages.concat([{
            id: optimisticId,
            role: "user",
            content: text,
            created_at: new Date().toISOString()
        }])

        request("POST", "/messages", { content: text },
            (data) => {
                sending = false
                let list = messages.filter(m => m.id !== optimisticId)
                list = list.concat([data.message]).concat(data.replies || [])
                messages = list
            },
            (err) => {
                sending = false
                sendError = err
                messages = messages.filter(m => m.id !== optimisticId)
            }
        )
    }
}
