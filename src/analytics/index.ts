import { EXLYTICS_URL, EXLYTICS_ACCOUNT } from './constants'

const recordPageview = (): boolean => {
  const analyticsUrl = new URL(EXLYTICS_URL)
  const pageUrl = new URL(window.location.toString())
  const data = {
    account_id: EXLYTICS_ACCOUNT,
    page: pageUrl.pathname
  }

  return navigator.sendBeacon(analyticsUrl.toString(), JSON.stringify(data))
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
    const anchor: HTMLAnchorElement = this.getElementsByTagName('a')[0]

    anchor.addEventListener('click', this.handleTrackedAnchorClick)
  }

  handleTrackedAnchorClick(event: Event): undefined {
    if (event.currentTarget instanceof HTMLAnchorElement === false) {
      return
    }

    const target = event.currentTarget as HTMLAnchorElement
    const analyticsUrl = new URL(EXLYTICS_URL)
    const data = {
      account_id: EXLYTICS_ACCOUNT,
      click_link: target.href
    }

    navigator.sendBeacon(analyticsUrl.toString(), JSON.stringify(data))
  }
}

customElements.define('tracked-anchor', TrackedAnchor)
