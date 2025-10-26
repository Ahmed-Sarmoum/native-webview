import { NativeWebiew } from 'native-webview';

window.testEcho = () => {
    const inputValue = document.getElementById("echoInput").value;
    NativeWebiew.echo({ value: inputValue })
}
