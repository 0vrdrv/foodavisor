import { ref } from "vue";

export const toastMessage = ref("");
export const toastVisible = ref(false);

export function showToast(msg, duration = 2500) {
  toastMessage.value = msg;
  toastVisible.value = true;

  setTimeout(() => {
    toastVisible.value = false;
  }, duration);
}
