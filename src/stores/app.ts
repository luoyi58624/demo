export const useAppStore = defineStore('app', {
  state: () => ({
    count: 0,
    disableIconCache: false
  }),
  getters: {
    double: state => state.count * 2
  },
  actions: {
    increment() {
      this.count++;
    }
  }
});
