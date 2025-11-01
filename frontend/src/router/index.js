import { createRouter, createWebHistory } from 'vue-router'
import Auth from '../pages/Auth.vue'
import Profile from '../pages/Profile.vue'

const routes = [
  { path: '/', redirect: '/auth' },
  { path: '/auth', component: Auth },
  { path: '/profile', component: Profile },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

export default router
