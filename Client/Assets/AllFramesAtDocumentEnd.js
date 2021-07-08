!function(e){var n={};function t(r){if(n[r])return n[r].exports;var i=n[r]={i:r,l:!1,exports:{}};return e[r].call(i.exports,i,i.exports,t),i.l=!0,i.exports}t.m=e,t.c=n,t.d=function(e,n,r){t.o(e,n)||Object.defineProperty(e,n,{enumerable:!0,get:r})},t.r=function(e){"undefined"!=typeof Symbol&&Symbol.toStringTag&&Object.defineProperty(e,Symbol.toStringTag,{value:"Module"}),Object.defineProperty(e,"__esModule",{value:!0})},t.t=function(e,n){if(1&n&&(e=t(e)),8&n)return e;if(4&n&&"object"==typeof e&&e&&e.__esModule)return e;var r=Object.create(null);if(t.r(r),Object.defineProperty(r,"default",{enumerable:!0,value:e}),2&n&&"string"!=typeof e)for(var i in e)t.d(r,i,function(n){return e[n]}.bind(null,i));return r},t.n=function(e){var n=e&&e.__esModule?function(){return e.default}:function(){return e};return t.d(n,"a",n),n},t.o=function(e,n){return Object.prototype.hasOwnProperty.call(e,n)},t.p="",t(t.s=8)}([,,,,,,,,function(e,n,t){t(9),t(10),t(11),t(12),t(13),e.exports=t(14)},function(e,n,t){"use strict";window.__firefox__||Object.defineProperty(window,"__firefox__",{enumerable:!1,configurable:!1,writable:!1,value:{userScripts:{},includeOnce:function(e,n){return!!__firefox__.userScripts[e]||(__firefox__.userScripts[e]=!0,"function"==typeof n&&n(),!1)}}})},function(e,n,t){"use strict";window.__firefox__.includeOnce("ContextMenu",(function(){window.addEventListener("touchstart",(function(e){var n=e.target,t=n.closest("a"),r=n.closest("img");if(t||r){var i={};i.touchX=e.changedTouches[0].pageX-window.scrollX,i.touchY=e.changedTouches[0].pageY-window.scrollY,t&&(i.link=t.href,i.title=t.textContent),r&&(i.image=r.src,i.title=i.title||r.title,i.alt=r.alt),(i.link||i.image)&&webkit.messageHandlers.contextMenuMessageHandler.postMessage(i)}}),!0)}))},function(e,n,t){"use strict";void 0===window.__firefox__.download&&Object.defineProperty(window.__firefox__,"download",{enumerable:!1,configurable:!1,writable:!1,value:function(e,n){if(n===SECURITY_TOKEN){if(e.startsWith("blob:")){var t=new XMLHttpRequest;return t.open("GET",e,!0),t.responseType="blob",t.onload=function(){if(200===this.status){var t=function(e){return e.split("/").pop()}(e),r=this.response;!function(e,n){var t=new FileReader;t.onloadend=function(){n(this.result.split(",")[1])},t.readAsDataURL(e)}(r,(function(e){webkit.messageHandlers.downloadManager.postMessage({securityToken:n,filename:t,mimeType:r.type,size:r.size,base64String:e})}))}},void t.send()}var r=document.createElement("a");r.href=e,r.dispatchEvent(new MouseEvent("click"))}}})},function(e,n,t){"use strict";window.__firefox__.includeOnce("FocusHelper",(function(){const e=e=>{const n=e.type,t=e.target.nodeName;("INPUT"===t||"TEXTAREA"===t||e.target.isContentEditable)&&((e=>{if("INPUT"!==e.nodeName)return!1;const n=e.type.toUpperCase();return"BUTTON"==n||"SUBMIT"==n||"FILE"==n})(e.target)||webkit.messageHandlers.focusHelper.postMessage({eventType:n,elementType:t}))},n={capture:!0,passive:!0},t=window.document.body;["focus","blur"].forEach(r=>{t.addEventListener(r,e,n)})}))},function(e,n,t){"use strict";window.__firefox__.includeOnce("LoginsHelper",(function(){function e(e){}var n={_getRandomId:function(){return Math.round(Math.random()*(Number.MAX_VALUE-Number.MIN_VALUE)+Number.MIN_VALUE).toString()},_messages:["RemoteLogins:loginsFound"],_requests:{},_takeRequest:function(e){var n=e,t=this._requests[n.requestId];return this._requests[n.requestId]=void 0,t},_sendRequest:function(e,n){var t=this._getRandomId();n.requestId=t,webkit.messageHandlers.loginsManagerMessageHandler.postMessage(n);var r=this;return new Promise((function(n,i){e.promise={resolve:n,reject:i},r._requests[t]=e}))},receiveMessage:function(e){var n=this._takeRequest(e);switch(e.name){case"RemoteLogins:loginsFound":n.promise.resolve({form:n.form,loginsFound:e.logins});break;case"RemoteLogins:loginsAutoCompleted":n.promise.resolve(e.logins)}},_asyncFindLogins:function(e,n){var i=this._getFormFields(e,!1);if(!i[0]||!i[1])return Promise.reject("No logins found");i[0].addEventListener("blur",r);var o=t._getPasswordOrigin(e.ownerDocument.documentURI),s=t._getActionOrigin(e);if(null==s)return Promise.reject("Action origin is null");var a={form:e},u={securityToken:SECURITY_TOKEN,type:"request",formOrigin:o,actionOrigin:s};return this._sendRequest(a,u)},loginsFound:function(e,n){this._fillForm(e,!0,!1,!1,!1,n)},onUsernameInput:function(n){var t=n.target;if(t.ownerDocument instanceof HTMLDocument&&this._isUsernameFieldType(t)){var r=t.form;if(r&&t.value){n.type;var[i,o,s]=this._getFormFields(r,!1);if(i==t&&o){var a=this;this._asyncFindLogins(r,{showMasterPassword:!1}).then((function(e){a._fillForm(e.form,!0,!0,!0,!0,e.loginsFound)})).then(null,e)}}}},_getPasswordFields:function(e,n){for(var t=[],r=0;r<e.elements.length;r++){var i=e.elements[r];i instanceof HTMLInputElement&&"password"==i.type&&(n&&!i.value||(t[t.length]={index:r,element:i}))}return 0==t.length?null:t.length>3?(t.length,null):t},_isUsernameFieldType:function(e){if(!(e instanceof HTMLInputElement))return!1;var n=e.hasAttribute("type")?e.getAttribute("type").toLowerCase():e.type;return"text"==n||"email"==n||"url"==n||"tel"==n||"number"==n},_getFormFields:function(e,n){var t,r,i=null,o=this._getPasswordFields(e,n);if(!o)return[null,null,null];for(var s=o[0].index-1;s>=0;s--){var a=e.elements[s];if(this._isUsernameFieldType(a)){i=a;break}}if(!n||1==o.length)return[i,o[0].element,null];var u=o[0].element.value,l=o[1].element.value,c=o[2]?o[2].element.value:null;if(3==o.length)if(u==l&&l==c)r=o[0].element,t=null;else if(u==l)r=o[0].element,t=o[2].element;else if(l==c)t=o[0].element,r=o[2].element;else{if(u!=c)return[null,null,null];r=o[0].element,t=o[1].element}else u==l?(r=o[0].element,t=null):(t=o[0].element,r=o[1].element);return[i,r,t]},_isAutocompleteDisabled:function(e){return!(!e||!e.hasAttribute("autocomplete")||"off"!=e.getAttribute("autocomplete").toLowerCase())},_onFormSubmit:function(e){var n=e.ownerDocument,r=n.defaultView;var i=t._getPasswordOrigin(n.documentURI);if(i){var o=t._getActionOrigin(e),s=this._getFormFields(e,!0),a=s[0],u=s[1],l=s[2];if(null!=u){this._isAutocompleteDisabled(e)||this._isAutocompleteDisabled(a)||this._isAutocompleteDisabled(u)||this._isAutocompleteDisabled(l),0;var c=a?{name:a.name,value:a.value}:null,d={name:u.name,value:u.value};l&&(l.name,l.value),r.opener&&r.opener.top;webkit.messageHandlers.loginsManagerMessageHandler.postMessage({securityToken:SECURITY_TOKEN,type:"submit",hostname:i,username:c.value,usernameField:c.name,password:d.value,passwordField:d.name,formSubmitURL:o})}}},_fillForm:function(e,n,t,r,i,o){var s=this._getFormFields(e,!1),u=s[0],l=s[1];if(null==l)return[!1,o];if(l.disabled||l.readOnly)return[!1,o];var c=Number.MAX_VALUE,d=Number.MAX_VALUE;u&&u.maxLength>=0&&(c=u.maxLength),l.maxLength>=0&&(d=l.maxLength);var f=(o=function(e,n){var t,r,i;if(null==e)throw new TypeError("Array is null or not defined");var o=Object(e),s=o.length>>>0;if("function"!=typeof n)throw new TypeError(n+" is not a function");arguments.length>1&&(t=e);r=new Array(s),i=0;for(;i<s;){var a,u;i in o&&(a=o[i],u=n.call(t,a,i,o),r[i]=u),i++}return r}(o,(function(e){return{hostname:e.hostname,formSubmitURL:e.formSubmitURL,httpRealm:e.httpRealm,username:e.username,password:e.password,usernameField:e.usernameField,passwordField:e.passwordField}}))).filter((function(e){var n=e.username.length<=c&&e.password.length<=d;return n||e.username,n}),this);if(0==f.length)return[!1,o];if(l.value&&!r)return"existingPassword",[!1,o];var m=!1;!t&&(this._isAutocompleteDisabled(e)||this._isAutocompleteDisabled(u)||this._isAutocompleteDisabled(l))&&(m=!0);var g=null;if(u&&(u.value||u.disabled||u.readOnly)){var p=u.value.toLowerCase();if((h=f.filter((function(e){return e.username.toLowerCase()==p}))).length){for(var v=0;v<h.length;v++){var _=h[v];_.username==u.value&&(g=_)}g||(g=h[0])}else"existingUsername"}else if(1==f.length)g=f[0];else{var h;g=(h=u?f.filter((function(e){return e.username})):f.filter((function(e){return!e.username})))[0]}var w=!1;if(g&&n&&!m){if(u){var b=u.disabled||u.readOnly,y=g.username!=u.value,F=i&&y&&u.value.toLowerCase()==g.username.toLowerCase();b||F||!y||(u.value=g.username,a(u,"keydown",40),a(u,"keyup",40))}l.value!=g.password&&(l.value=g.password,a(l,"keydown",40),a(l,"keyup",40)),w=!0}else g&&!n?"noAutofillForms":g&&m&&"autocompleteOff";return[w,o]}},t={_getPasswordOrigin:function(e,n){return e},_getActionOrigin:function(e){var n=e.action;return""==n&&(n=e.baseURI),this._getPasswordOrigin(n,!0)}};function r(e){n.onUsernameInput(e)}var i=document.body;function o(e){for(var n=0;n<e.length;n++){var t=e[n];"FORM"===t.nodeName?s(t):t.hasChildNodes()&&o(t.childNodes)}return!1}function s(t){try{n._asyncFindLogins(t,{}).then((function(e){n.loginsFound(e.form,e.loginsFound)})).then(null,e)}catch(e){}}function a(e,n,t){var r=document.createEvent("KeyboardEvent");r.initKeyboardEvent(n,!0,!0,window,0,0,0,0,0,t),e.dispatchEvent(r)}new MutationObserver((function(e){for(var n=0;n<e.length;++n)o(e[n].addedNodes)})).observe(i,{attributes:!1,childList:!0,characterData:!1,subtree:!0}),window.addEventListener("load",(function(e){for(var n=0;n<document.forms.length;n++)s(document.forms[n])})),window.addEventListener("submit",(function(e){try{n._onFormSubmit(e.target)}catch(e){}})),Object.defineProperty(window.__firefox__,"logins",{enumerable:!1,configurable:!1,writable:!1,value:Object.freeze(new function(){this.inject=function(e){try{n.receiveMessage(e)}catch(e){}}})})}))},function(e,n,t){"use strict";window.__firefox__.includeOnce("PrintHandler",(function(){window.print=function(){webkit.messageHandlers.printHandler.postMessage({})}}))}]);