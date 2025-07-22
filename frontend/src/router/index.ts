import { createRouter, createWebHistory } from 'vue-router'
import Dashboard from '../views/Dashboard.vue'
import Payments from '../views/Payments.vue'
import Orders from '../views/Orders.vue'
import Flags from '../views/Flags.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      name: 'Dashboard',
      component: Dashboard
    },
    {
      path: '/payments',
      name: 'Payments',
      component: Payments
    },
    {
      path: '/orders',
      name: 'Orders',
      component: Orders
    },
    {
      path: '/flags',
      name: 'Flags',
      component: Flags
    }
  ]
})

export default router 