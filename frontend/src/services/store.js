import { reactive } from "vue";
import api from "./api";

const state = reactive({
  user: null,
  token: localStorage.getItem("token") || null,
});

export function useAuthStore() {
  return {
    // état
    get user() {
      return state.user;
    },
    get token() {
      return state.token;
    },

    // méthode centrale pour mettre à jour auth
    setAuth(token, user) {
      state.token = token;
      state.user = user;

      if (token) {
        localStorage.setItem("token", token);
      } else {
        localStorage.removeItem("token");
      }
    },

    // login classique
    async login(email, password) {
      const { data } = await api.post("/auth/login", { email, password });
      this.setAuth(data.token, data.user);
    },

    // récup /auth/me au démarrage
    async fetchMe() {
      if (!state.token) return;
      const { data } = await api.get("/auth/me");
      state.user = data;
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
