<template>
  <div class="bg-slate-950 text-slate-100 min-h-screen">
    <AppSidebar v-if="auth.isAuthenticated()" />
    <AppNavbar v-if="auth.isAuthenticated()" />
    
    <main class="pt-20 pl-64 pr-8 pb-8">
      <RouterView />
    </main>
  </div>
  <Toast />
</template>

<script setup>
import AppSidebar from "./components/layout/AppSidebar.vue";
import AppNavbar from "./components/layout/AppNavbar.vue";
import { useAuthStore } from "./services/store";
import Toast from "./components/common/Toast.vue";

const auth = useAuthStore();
</script>
