import './styles.scss'

class LoadComments extends HTMLElement {
  constructor() {
    super()

    this.addEventListener('click', this.loadComments)
  }

  loadComments() {
    const commento = document.createElement('div')

    commento.id = 'commento'
    commento.dataset.noFonts = true
    commento.dataset.pageId = this.getAttribute('slug')

    this.parentNode.appendChild(commento)

    const commentoScript = document.createElement('script')
    commentoScript.src = 'https://commento.corybuecker.com/js/commento.js'
    this.parentNode.appendChild(commentoScript)

    this.remove()
  }
}

customElements.define('load-comments', LoadComments)