import { createRouter, createWebHistory } from 'vue-router'
import Auth from '../pages/Auth.vue'

const routes = [
  { path: '/', redirect: '/auth' },
  { path: '/auth', component: Auth },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

export default router
