import * as htmx from 'htmx.org';
import hljs from 'highlight.js/lib/core'
import elixir from 'highlight.js/lib/languages/elixir'
import javascript from 'highlight.js/lib/languages/javascript'
import bash from 'highlight.js/lib/languages/bash'
import yaml from 'highlight.js/lib/languages/yaml'
import dockerfile from 'highlight.js/lib/languages/dockerfile'
import nginx from 'highlight.js/lib/languages/nginx'
import css from 'highlight.js/lib/languages/css'
import plaintext from 'highlight.js/lib/languages/plaintext'

declare global {
  interface Window { htmx: any, afterBoostSwap: any }
}

hljs.registerLanguage('elixir', elixir)
hljs.registerLanguage('javascript', javascript)
hljs.registerLanguage('bash', bash)
hljs.registerLanguage('yaml', yaml)
hljs.registerLanguage('dockerfile', dockerfile)
hljs.registerLanguage('nginx', nginx)
hljs.registerLanguage('css', css)
hljs.registerLanguage('plaintext', plaintext)

const localizeTimeElements = () => {
  const timeElements: HTMLCollectionOf<HTMLTimeElement> = document.getElementsByTagName('time')
  for (const el of timeElements) {
    const timeString = el.dateTime
    el.innerText = new Date(timeString).toLocaleDateString()
  }
}

const afterBoostSwap = () => {
  localizeTimeElements()
  hljs.highlightAll()
}

window.afterBoostSwap = afterBoostSwap
window.htmx = htmx