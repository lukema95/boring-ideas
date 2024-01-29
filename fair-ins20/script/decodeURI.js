const { DOMParser } = require('xmldom');

// Extracting the base64-encoded JSON part
const solidityOutput = "data:application/json;base64,eyJkZXNjcmlwdGlvbiI6ICJGQUlSLUlOUzIwIGlzIGEgc29jaWFsIGV4cGVyaW1lbnQgYW5kIGEgZmFpciBkaXN0cmlidXRpb24gb2YgSU5TMjAuIiwgImltYWdlIjogImRhdGE6aW1hZ2Uvc3ZnK3htbDtiYXNlNjQsUEhOMlp5QjRiV3h1Y3owaWFIUjBjRG92TDNkM2R5NTNNeTV2Y21jdk1qQXdNQzl6ZG1jaUlIQnlaWE5sY25abFFYTndaV04wVW1GMGFXODlJbmhOYVc1WlRXbHVJRzFsWlhRaUlIWnBaWGRDYjNnOUlqQWdNQ0F6TlRBZ016VXdJajRnUEhOMGVXeGxQaTVpWVhObElIc2dabWxzYkRvZ1ozSmxaVzQ3SUdadmJuUXRabUZ0YVd4NU9pQnpaWEpwWmpzZ1ptOXVkQzF6YVhwbE9pQXhOSEI0T3lCOVBDOXpkSGxzWlQ0OGNtVmpkQ0IzYVdSMGFEMGlNVEF3SlNJZ2FHVnBaMmgwUFNJeE1EQWxJaUJtYVd4c1BTSmliR0ZqYXlJZ0x6NDhkR1Y0ZENCNFBTSXhNREFpSUhrOUlqRXdNQ0lnWTJ4aGMzTTlJbUpoYzJVaVBuczhMM1JsZUhRK1BIUmxlSFFnZUQwaU1UTXdJaUI1UFNJeE16QWlJR05zWVhOelBTSmlZWE5sSWo0aWNDSTZJbWx1Y3kweU1DSXNQQzkwWlhoMFBqeDBaWGgwSUhnOUlqRXpNQ0lnZVQwaU1UWXdJaUJqYkdGemN6MGlZbUZ6WlNJK0ltOXdJam9pSWl3OEwzUmxlSFErUEhSbGVIUWdlRDBpTVRNd0lpQjVQU0l4T1RBaUlHTnNZWE56UFNKaVlYTmxJajRpZEdsamF5STZJbVpoYVhJaUxEd3ZkR1Y0ZEQ0OGRHVjRkQ0I0UFNJeE16QWlJSGs5SWpJeU1DSWdZMnhoYzNNOUltSmhjMlVpUGlKaGJYUWlPakE4TDNSbGVIUStQSFJsZUhRZ2VEMGlNVEF3SWlCNVBTSXlOVEFpSUdOc1lYTnpQU0ppWVhObElqNTlQQzkwWlhoMFBqd3ZjM1puUGc9PSJ9"

const base64Json = solidityOutput.split('data:application/json;base64,')[1];

const decodedJson = atob(base64Json);
console.log('Decoded JSON:', decodedJson);

const parsedObject = JSON.parse(decodedJson);

const base64Svg = parsedObject.image.split('data:image/svg+xml;base64,')[1];
console.log('Base64 SVG:', base64Svg);

const decodedSvg = atob(base64Svg);
console.log('Decoded SVG:', decodedSvg);

const parser = new DOMParser();

const svgDoc = parser.parseFromString(decodedSvg, 'image/svg+xml');

const textNodes = svgDoc.documentElement.getElementsByTagName('text');

// 查找包含 "amt" 的文本节点并提取值
let amtValue = null;
for (let i = 0; i < textNodes.length; i++) {
  const textContent = textNodes[i].textContent.trim();
  if (textContent.startsWith('"amt"')) {
    // 通过正则表达式提取 "amt" 字段的值
    const match = textContent.match(/"amt"\s*:\s*([^,}]+)/);
    if (match) {
      amtValue = match[1].trim();
    }
    break;
  }
}

console.log('Amount Value:', amtValue);

