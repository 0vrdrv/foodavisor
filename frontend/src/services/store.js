import { reactive } from "vue";
import api from "./api";
import { loadUserPreferences } from "./preferences";

const state = reactive({
  user: null,
  token: localStorage.getItem("token") || null,
});

export function useAuthStore() {
  return {
    get user() {
      return state.user;
    },
    get token() {
      return state.token;
    },

    setAuth(token, user) {
      state.token = token;
      state.user = user;

      if (token) {
        localStorage.setItem("token", token);
      } else {
        localStorage.removeItem("token");
      }
    },

    async login(email, password) {
      const { data } = await api.post("/auth/login", { email, password });
      this.setAuth(data.token, data.user);

      // 🔥 charger immédiatement les préférences
      await loadUserPreferences();
    },

    async fetchMe() {
      if (!state.token) return;

      const { data } = await api.get("/auth/me");
      state.user = data;

      // 🔥 charge aussi les prefs au démarrage
      await loadUserPreferences();
    },

    logout() {
      this.setAuth(null, null);
    },

    isAuthenticated() {
      return !!state.token;
    },

    isAdmin() {
      return state.user?.roles?.includes("ADMIN");
    },
  };
}
