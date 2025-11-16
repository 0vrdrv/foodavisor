<template>
  <transition name="fade">
    <div
      v-if="visible"
      class="fixed bottom-6 right-6 bg-slate-800 text-white px-4 py-3 rounded shadow-lg border border-slate-700"
    >
      {{ message }}
    </div>
  </transition>
</template>

<script setup>
import { toastVisible as visible, toastMessage as message } from "../../services/toast.js";
</script>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity .25s;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
