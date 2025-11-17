<template>
  <aside
    class="w-64 bg-slate-900 border-r border-slate-800 h-screen fixed left-0 top-0 flex flex-col shadow-lg"
  >
    <!-- Logo -->
    <div class="p-5 border-b border-slate-800">
      <h1 class="text-lg font-semibold text-slate-100 tracking-wide">
        FoodAdvisor
      </h1>
      <p class="text-xs mt-1 text-slate-500">Votre assistant culinaire</p>
    </div>

    <!-- Navigation -->
    <nav class="flex-1 overflow-y-auto py-4 space-y-1">

      <RouterLink
        v-for="item in menu"
        :key="item.to"
        :to="item.to"
        class="flex items-center px-5 py-2 text-sm text-slate-300 hover:bg-slate-800 hover:text-emerald-400 transition-colors"
        :class="{ 'bg-slate-800 text-emerald-400': isActive(item.to) }"
      >
        <component :is="item.icon" class="w-4 h-4 mr-3" />
        {{ item.label }}
      </RouterLink>

      <!-- ADMIN SECTION -->
      <div v-if="auth.isAdmin()" class="pt-4 mt-4 border-t border-slate-800">
        <p class="px-5 text-xs uppercase text-slate-500 mb-2">Administration</p>

        <RouterLink
          v-for="item in adminMenu"
          :key="item.to"
          :to="item.to"
          class="flex items-center px-5 py-2 text-sm text-slate-300 hover:bg-slate-800 hover:text-emerald-400 transition-colors"
          :class="{ 'bg-slate-800 text-emerald-400': isActive(item.to) }"
        >
          <component :is="item.icon" class="w-4 h-4 mr-3" />
          {{ item.label }}
        </RouterLink>
      </div>
    </nav>

    <!-- Footer -->
    <div class="p-4 border-t border-slate-800 text-xs text-slate-600">
      © FoodAdvisor, 2025
    </div>
  </aside>
</template>

<script setup>
import { useAuthStore } from "../../services/store";
import { useRoute } from "vue-router";

import {
  Home,
  Search,
  Book,
  Package,
  Flame,
  BookmarkCheck,
  BarChart2,
  Settings,
  Users,
  ListChecks,
  ChefHat
} from "lucide-vue-next";

const auth = useAuthStore();
const route = useRoute();

const isActive = (path) => route.path.startsWith(path);

const menu = [
  { label: "Dashboard", to: "/dashboard", icon: Home },
  { label: "Recommandations", to: "/recommandations", icon: ChefHat },
  { label: "Recherche", to: "/search", icon: Search },
  { label: "Recettes", to: "/recettes", icon: Book },
  { label: "Ingrédients", to: "/ingredients", icon: ListChecks },
  { label: "Stock", to: "/stocks", icon: Package },
  { label: "Listes de courses", to: "/listes", icon: BookmarkCheck },
  { label: "Cuissons", to: "/cuissons", icon: Flame },
  { label: "Mes stats", to: "/stats", icon: BarChart2 },
  { label: "Préférences", to: "/preferences", icon: Settings },
];

const adminMenu = [
  { label: "Utilisateurs", to: "/admin/users", icon: Users },
  { label: "Allergènes", to: "/allergenes", icon: ListChecks },
  { label: "Stats globales", to: "/stats/global", icon: BarChart2 },
];
</script>
