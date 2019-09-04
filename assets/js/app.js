// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import 'bootstrap';
import css from "../css/app.scss";

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative paths, for example:
// import socket from "./socket"

// assets/js/app.js
import LiveSocket from "phoenix_live_view"

let liveSocket = new LiveSocket("/live")
liveSocket.connect()


const targetNode = document.getElementById("chatscroll")


document.addEventListener("DOMContentLoaded", function() {
    console.log(targetNode)
  targetNode.scrollTop = targetNode.scrollHeight
});
// Options for the observer (which mutations to observe)
let config = { attributes: true, childList: true, subtree: true };
// Callback function to execute when mutations are observed
var callback = function(mutationsList, observer) {
  for(var mutation of mutationsList) {
    if (mutation.type == 'childList') {
    //   diff = targetNode.scrollHeight - targetNode.scrollTop
      console.log("==>  <=====")
    //   if (diff < 800) {
        targetNode.scrollTop = targetNode.scrollHeight
    //   } else {
        // targetNode.scrollTop = targetNode.scrollHeight
    //   }
    }
  }
};
// Create an observer instance linked to the callback function
var observer = new MutationObserver(callback);
// Start observing the target node for configured mutations
observer.observe(targetNode, config);
