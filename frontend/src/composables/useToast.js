import { ref } from "vue";

const message = ref("");
const type = ref("success"); // success | error | warning
const visible = ref(false);

let timeout = null;

export function useToast() {
  const showToast = (text, t = "success", duration = 2500) => {
    message.value = text;
    type.value = t;
    visible.value = true;

    clearTimeout(timeout);
    timeout = setTimeout(() => {
      visible.value = false;
    }, duration);
  };

  return {
    message,
    type,
    visible,
    showToast,
  };
}
