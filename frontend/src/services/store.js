import { reactive } from "vue";
import api from "./api";

const state = reactive({
  user: null,
  token: localStorage.getItem("token") || null,
});

export function useAuthStore() {
  return {
    user: state.user,
    token: state.token,

    async login(email, password) {
      const { data } = await api.post("/auth/login", { email, password });

      state.token = data.token;
      state.user = data.user;

      localStorage.setItem("token", data.token);
    },

    async fetchMe() {
      if (!state.token) return;
      const { data } = await api.get("/auth/me");
      state.user = data;
    },

    logout() {
      state.token = null;
      state.user = null;
      localStorage.removeItem("token");
    },

    isAuthenticated() {
  return !!this.token;
},


    isAdmin() {
      return state.user?.roles?.includes("ADMIN");
    }
  };
}
