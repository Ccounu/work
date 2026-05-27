import { createRouter, createWebHistory } from 'vue-router'
import BackendLayout from '@/components/BackenLayout.vue'
import AuthLayout from '@/components/AuthLayout.vue'
import FrontendLayout from '@/components/FrontendLayout.vue'

//路由配置
const backendRoutes = [
  {
    path: '/back',
    redirect: '/back/dashboard',
    component: BackendLayout,
    children: [
      {
        path: 'dashboard',
        component: () => import('@/view/dashboard.vue'),
        meta: {
          title: '数据分析',
          icon: 'PieChart',
        },
      },
      {
        path: 'knowledge',
        component: () => import('@/view/knowledge.vue'),
        meta: {
          title: '知识文章',
          icon: 'ChatLineSquare',
        },
      },
      {
        path: 'consultations',
        component: () => import('@/view/consultations.vue'),
        meta: {
          title: '咨询记录',
          icon: 'Message',
        },
      },
      {
        path: 'emotional',
        component: () => import('@/view/emotional.vue'),
        meta: {
          title: '情绪日志',
          icon: 'User',
        },
      },
    ],
  },
  {
    path: '/auth',
    component: AuthLayout,
    children: [
      {
        path: 'login',
        component: () => import('@/view/login.vue'),
        meta: {
          title: '登录'
        },
      },
      {
        path: 'register',
        component: () => import('@/view/register.vue'),
        meta: {
          title: '注册'
        },
      }
    ]
  }
]

const frontendRoutes = [
  {
    path: '/',
    component: FrontendLayout,
    children: [
      {
        path: '/',
        component: () => import('@/view/home.vue')
      },
      {
        path: '/knowledge',
        component: () => import('@/view/frontendKnowledge.vue')
      },
      {
        path: '/consultation',
        component: () => import('@/view/consultation.vue')
      },
      {
        path: '/emotion-diary',
        component: () => import('@/view/emotionDiary.vue')
      },
      {
        path: 'knowledge/article/:id',
        component: () => import('@/view/articleDetail.vue'),
        props: true
      }
    ]
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes: [...backendRoutes, ...frontendRoutes]
})

// 路由前置守卫
router.beforeEach((to, from, next) => {
  // 检查是否有token
  const token = localStorage.getItem('token')
  // 当前用户是否登录
  if (token){
    const userInfo = JSON.parse(localStorage.getItem('userInfo'))
    // 如果是后台用户
    if (userInfo.userType === 2){
      if (to.path.startsWith('/back')) {
        next()
      } else {
        next('/back/dashboard')
      }
    } else if(userInfo.userType === 1) {
      // 用户端账号只能访问前台路由
      if (to.path.startsWith('/back') || to.path.startsWith('/auth')) {
        next('/')
      } else {
        next()
      }
    }
  } else {
    // 如果没有token，重定向到登录页
    if(to.path.startsWith('/back')){
      // 如果是访问后台页面，那么跳转到登录页
      next('/auth/login')
    } else {
      next()
    }
  }
})

export default router
