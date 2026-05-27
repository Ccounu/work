import { createRouter, createWebHistory } from 'vue-router'

const router = [
  {
    path: '/',
    name: 'Home',
    component: () => import('@/views/Home.vue')
  },
  {
    path: '/chat',
    name: 'Chat',
    component: () => import('@/views/Chat.vue')
  },
  {
    path: '/profile',
    name: 'Profile',
    component: () => import('@/views/Profile.vue')
  },
  {
    path: '/detail',
    name: 'Detail',
    component: () => import('@/views/Detail.vue')
  }
]

const route = createRouter({
  history: createWebHistory(),
  routes: router
})

export default route
