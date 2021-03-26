// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import {Socket} from "phoenix"
import NProgress from "nprogress"
import {LiveSocket} from "phoenix_live_view"

import {copyToClipboard} from "./clipboard"
window.$ = {
    copyToClipboard
}

let hooks = {}

hooks.responseCopyToClipboard = {
    mounted() {
        console.log("copyToClipboard: mounted")
        this.handleEvent("responseCopyToClipboard", ({text}) => {
            debugger;
            copyToClipboard(text);
        })
    }
}

hooks.messenger = {
    mounted() {
        console.log("messenger is mounted")
        window.socketMessenger = {
            sendClipboardData: (data) => {
                this.pushEvent("paste", {pasteData: data}, (reply, ref) => { })
            },
            pasteClipboard: (mimeType, data, name) => {
                this.pushEvent("paste", {mimeType: mimeType, data: data, name: name}, (reply, ref) => {
                    console.log("in callback reply/ref");
                })
            },
            sendText: (mimeType, text) => {
                this.pushEvent("pasteText", {mimeType: mimeType, text: text}, (reply, ref) => {
                    console.log("in callback reply/ref");
                })
            },
            sendFile: (mimeType, filename, base64) => {
                this.pushEvent("pasteFile", {mimeType: mimeType, filename: filename, base64: base64}, (reply, ref) => {
                    console.log("in callback reply/ref");
                })
            },
        }
    }
}

hooks.whatever = {
    mounted() {
        console.log("whatever was mounted!")
        this.el.addEventListener("paste", pasteEvent => {
            // async events seem unsupported...
            //debugger;
            let data = (pasteEvent.clipboardData || window.clipboardData).getData('text');
            console.log("Got something from a paste event: " + data)

            this.pushEvent("paste", {pasteData: data}, (reply, ref) => { })

            // let items = await navigator.clipboard.read();
            // for (let item of items) {
            //   if (!item.types.includes("text/html"))
            //       continue;
            //   let reader = new FileReader;
            //   reader.addEventListener("load", loadEvent => {
            //       debugger;
            //       //document.getElementById("html-output").innerHTML = reader.result;
            //   });
            //   reader.readAsText(await item.getType("text/html"));
            //   break;
            // }
        })
        this.el.focus()
    }
}

hooks.copyToClipboard = {
    mounted() {

    }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks: hooks})

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => NProgress.start())
window.addEventListener("phx:page-loading-stop", info => NProgress.done())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// ?
export { }