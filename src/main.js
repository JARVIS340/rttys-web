import Vue from 'vue'
import App from './App.vue'
import router from './router'
import axios from 'axios'
import VueAxios from 'vue-axios'
import VueTimers from 'vue-timers'
import i18n from './plugins/vue-i18n'
import './plugins/view-design'
import './assets/iconfont/iconfont.css'

Vue.config.productionTip = false

Vue.use(VueAxios, axios);
Vue.use(VueTimers)

new Vue({
  router,
  i18n,
  render: h => h(App)
}).$mount('#app')
