const MESSAGES = {
  required: {
    email: "Enter your email address.",
    password: "Enter your password.",
    name: "Enter your name.",
  },
  email: "Enter a valid email address.",
  min8: "Password must be at least 8 characters long.",
};

function fieldName(input) {
  return input.dataset.field || input.name.split("[").pop()?.replace("]", "");
}

function validateRule(input, rule) {
  const value = input.value.trim();
  const name = fieldName(input);

  switch (rule) {
    case "required":
      if (!value) {
        return MESSAGES.required[name] || "This field is required.";
      }
      return null;

    case "email":
      if (!value) return null;
      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)) {
        return MESSAGES.email;
      }
      return null;

    case "min:8":
      if (!value) return null;
      if (value.length < 8) {
        return MESSAGES.min8;
      }
      return null;

    default:
      return null;
  }
}

function validateInput(input) {
  const rules = (input.dataset.validate || "").split(",").map((r) => r.trim());

  for (const rule of rules) {
    const message = validateRule(input, rule);
    if (message) return message;
  }

  return null;
}

function errorElement(input) {
  return document.querySelector(`[data-error-for="${input.id}"]`);
}

function setFieldError(input, message) {
  const errorEl = errorElement(input);

  if (message) {
    input.classList.add("border-error");
    input.classList.remove("border-base-300");
    if (errorEl) {
      errorEl.textContent = message;
      errorEl.classList.remove("hidden");
    }
  } else {
    input.classList.remove("border-error");
    input.classList.add("border-base-300");
    if (errorEl) {
      errorEl.textContent = "";
      errorEl.classList.add("hidden");
    }
  }
}

function validateField(input, { show } = { show: true }) {
  const message = validateInput(input);
  if (show) setFieldError(input, message);
  return !message;
}

function setupPasswordToggle(button) {
  const inputId = button.dataset.target;
  const input = document.getElementById(inputId);
  const icon = button.querySelector("[data-toggle-icon]");

  if (!input || !icon) return;

  button.addEventListener("click", () => {
    const showing = input.type === "text";
    input.type = showing ? "password" : "text";
    icon.classList.toggle("hero-eye", showing);
    icon.classList.toggle("hero-eye-slash", !showing);
  });
}

function setupForm(form) {
  const inputs = form.querySelectorAll(".sso-field-input");

  inputs.forEach((input) => {
    input.addEventListener(
      "blur",
      () => {
        validateField(input);
      },
      { passive: true },
    );

    input.addEventListener("input", () => {
      const errorEl = errorElement(input);
      if (errorEl && !errorEl.classList.contains("hidden")) {
        validateField(input);
      }
    });
  });

  form.querySelectorAll(".sso-password-toggle").forEach(setupPasswordToggle);

  form.addEventListener("submit", (event) => {
    let valid = true;

    inputs.forEach((input) => {
      if (!validateField(input)) valid = false;
    });

    if (!valid) event.preventDefault();
  });
}

function initSsoForms() {
  document.querySelectorAll("form[data-sso-form]").forEach(setupForm);
}

document.addEventListener("DOMContentLoaded", initSsoForms);
document.addEventListener("phx:page-loading-stop", initSsoForms);

export default { initSsoForms };
