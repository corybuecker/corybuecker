const recordPageview = (): Promise<{}> => {
  const analyticsUrl = new URL('https://analytics.corybuecker.com')
  const pageUrl = new URL(window.location.toString())

  analyticsUrl.search = `page=${pageUrl.pathname}`

  return fetch(analyticsUrl.toString())
}

recordPageview()

const formatTimeElement = (element: HTMLTimeElement): void => {
  const timeString = element.dateTime

  element.innerText = new Date(timeString).toLocaleDateString()
}

const timeElements = document.getElementsByTagName('time')

Array.from(timeElements).forEach(formatTimeElement)

class TrackedAnchor extends HTMLElement {
  constructor() {
    super()

    this.addEventListener('click', this.handleTrackedAnchorClick)
  }

  handleTrackedAnchorClick(event: Event) {
    event.preventDefault()
    event.stopPropagation()

    const target = event.target as HTMLAnchorElement
    const analyticsUrl = new URL('https://analytics.corybuecker.com')

    analyticsUrl.search = `click_link=${target?.href}`

    fetch(analyticsUrl.toString())
      .then(() => (window.location.href = target?.href))
      .catch(() => (window.location.href = target?.href))

    return false
  }
}

window.customElements.define('tracked-anchor', TrackedAnchor)
