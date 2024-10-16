import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    const alerts = this.create_alert_list();
    this.dismiss_alerts(alerts);
  }

  create_alert_list() {
    const alertList = document.querySelectorAll(".alert:not(#alert-modal)");
    const alerts = [...alertList].map(
      (element) => new bootstrap.Alert(element)
    );
    return alerts;
  }

  dismiss_alerts(alerts) {
    if (alerts.length > 0) {
      for (let index = 0; index < alerts.length; index++) {
        setTimeout(() => {
          alerts[index].close();
        }, 2000);
      }
    }
  }
}
