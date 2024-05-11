import * as htmx from 'htmx.org';
import hljs from 'highlight.js/lib/core'

import elixir from 'highlight.js/lib/languages/elixir'
import javascript from 'highlight.js/lib/languages/javascript'
import bash from 'highlight.js/lib/languages/bash'
import yaml from 'highlight.js/lib/languages/yaml'

declare global {
    interface Window { htmx: any; }
}

hljs.registerLanguage('elixir', elixir)
hljs.registerLanguage('javascript', javascript)
hljs.registerLanguage('bash', bash)
hljs.registerLanguage('yaml', yaml)

hljs.highlightAll()

window.htmx = htmx;