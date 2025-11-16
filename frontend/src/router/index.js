import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../services/store'

import LoginView from '../views/auth/LoginView.vue'
import RegisterView from '../views/auth/RegisterView.vue'

import UserDashboard from '../views/dashboard/UserDashboard.vue'
import AdminDashboard from '../views/dashboard/AdminDashboard.vue'

import IngredientsListView from '../views/ingredients/IngredientsListView.vue'
import IngredientFormView from '../views/ingredients/IngredientFormView.vue'

import RecettesListView from '../views/recettes/RecettesListView.vue'
import RecetteDetailView from '../views/recettes/RecetteDetailView.vue'
import RecetteFormView from '../views/recettes/RecetteFormView.vue'

import RecommandationsView from '../views/recommandations/RecommandationsView.vue'
import SearchRecettesView from '../views/search/SearchRecettesView.vue'

import StocksView from '../views/stocks/StocksView.vue'
import ListesCoursesView from '../views/listes/ListesCoursesView.vue'
import CuissonsView from '../views/cuissons/CuissonsView.vue'

import PreferencesView from '../views/preferences/PreferencesView.vue'
import AllergensView from '../views/allergenes/AllergensView.vue'

import StatsUserView from '../views/stats/StatsUserView.vue'
import StatsGlobalView from '../views/stats/StatsGlobalView.vue'

import UsersListView from '../views/users/UsersListView.vue'

const routes = [
  { path: '/login', name: 'login', component: LoginView },
  { path: '/register', name: 'register', component: RegisterView },

  { path: '/', redirect: '/dashboard' },
  {
    path: '/dashboard',
    name: 'user-dashboard',
    component: UserDashboard,
    meta: { requiresAuth: true },
  },
  {
    path: '/admin',
    name: 'admin-dashboard',
    component: AdminDashboard,
    meta: { requiresAuth: true, adminOnly: true },
  },

  // Profil & préférences
  {
    path: '/preferences',
    name: 'preferences',
    component: PreferencesView,
    meta: { requiresAuth: true },
  },

  {
    path: '/profil',
    name: 'profil',
    redirect: '/preferences',
    meta: { requiresAuth: true },
  },

  // INGREDIENTS (User + Admin)
  {
    path: '/ingredients',
    name: 'ingredients',
    component: () => import('../views/ingredients/IngredientsListView.vue'),
    meta: { requiresAuth: true },
  },
  {
    path: '/ingredients/new',
    name: 'ingredient-new',
    component: () => import('../views/ingredients/IngredientFormView.vue'),
    meta: { requiresAuth: true },
  },
  {
    path: '/ingredients/:id',
    name: 'ingredient-detail',
    component: () => import('../views/ingredients/IngredientDetailView.vue'),
    meta: { requiresAuth: true },
  },
  {
    path: '/ingredients/:id/edit',
    name: 'ingredient-edit',
    component: () => import('../views/ingredients/IngredientFormView.vue'),
    meta: { requiresAuth: true },
  },

  // Allergènes (admin / gestion)
  {
    path: '/allergenes',
    name: 'allergenes',
    component: AllergensView,
    meta: { requiresAuth: true },
  },

  // Recettes
  {
    path: '/recettes',
    name: 'recettes',
    component: RecettesListView,
    meta: { requiresAuth: true },
  },
  {
    path: '/recettes/new',
    name: 'recette-new',
    component: RecetteFormView,
    meta: { requiresAuth: true },
  },
  {
    path: '/recettes/:id',
    name: 'recette-detail',
    component: RecetteDetailView,
    meta: { requiresAuth: true },
  },
  {
    path: '/recettes/:id/edit',
    name: 'recette-edit',
    component: RecetteFormView,
    meta: { requiresAuth: true },
  },

  // Recommandations
  {
    path: '/recommandations',
    name: 'recommandations',
    component: RecommandationsView,
    meta: { requiresAuth: true },
  },

  // Recherche
  {
    path: '/search',
    name: 'recettes-search',
    component: SearchRecettesView,
    meta: { requiresAuth: true },
  },

  // Stocks
  { path: '/stocks', name: 'stocks', component: StocksView, meta: { requiresAuth: true } },

  // Listes de courses
  { path: '/listes', name: 'listes', component: ListesCoursesView, meta: { requiresAuth: true } },

  // Cuissons & historique
  { path: '/cuissons', name: 'cuissons', component: CuissonsView, meta: { requiresAuth: true } },

  // Stats
  { path: '/stats', name: 'stats-user', component: StatsUserView, meta: { requiresAuth: true } },
  {
    path: '/stats/global',
    name: 'stats-global',
    component: StatsGlobalView,
    meta: { requiresAuth: true, adminOnly: true },
  },

  // Users (admin)
  {
    path: '/admin/users',
    name: 'users-list',
    component: UsersListView,
    meta: { requiresAuth: true, adminOnly: true },
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

// Protection des routes requiresAuth
router.beforeEach(async (to, from, next) => {
  const auth = useAuthStore()

  // Si on a un token mais pas de user en mémoire, on récupère /auth/me
  if (auth.token && !auth.user) {
    try {
      await auth.fetchMe()
    } catch {
      auth.logout()
    }
  }

  if (to.meta.requiresAuth && !auth.isAuthenticated()) {
    return next('/login')
  }

  next()
})

export default router
