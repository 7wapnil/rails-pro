import $ from 'jquery';

export default class RecaptchaVerification {
  static get FORM_SELECTOR() { return '.js-recaptcha-form' }
  static get RECAPTCHA_SELECTOR() { return '.g-recaptcha-response' }

  constructor() {
    this.$form = $(RecaptchaVerification.FORM_SELECTOR);
    this.$recaptchaContainer = this.$form.find('.g-recaptcha');
  }

  init() {
    if (!this.isEnabled()) return;

    this.$form.on('submit', this.onSubmit(this));
    this.$form
      .on('change', RecaptchaVerification.RECAPTCHA_SELECTOR, this.onRecaptchaChanged(this))
  }

  isEnabled() {
    return this.$recaptchaContainer.length > 0
  }

  onSubmit() {
    return () => {
      if (!this.isProvided()) this.showError();

      return this.isProvided()
    }
  }

  isProvided() {
    return this.$form.find('#g-recaptcha-response').val().length > 0
  }

  showError() {
    if (this.$form.find('.recaptcha-error').length) return;

    this
      .$recaptchaContainer
      .append('<p class="recaptcha-error">Please, pass Captcha verification!</p>');
  }

  onRecaptchaChanged() {
    return (e) => {
      if (e.currentTarget.value.length) {
        this.hideError();
      } else {
        this.showError();
      }
    }
  }

  hideError() {
    this.$form.find('.recaptcha-error').remove()
  }
}

window.onRecaptchaSuccess = (token) => {
  $(RecaptchaVerification.RECAPTCHA_SELECTOR)
    .filter(function() { return this.value === token })
    .trigger('change')
};

$(document).on('turbolinks:load', () => new RecaptchaVerification().init());
