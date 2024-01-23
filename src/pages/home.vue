<script setup lang="ts">
const appStore = useAppStore()
const count = ref(0)

</script>

<template>
  <div class="h-screen flex flex-col items-center justify-center">
    <HelloWorld msg="Vite + Vue" v-model:count="count" />
    <p>store count: {{ appStore.count }}</p>
    <button class="btn-primary" @click="$router.push('/test')">测试页面</button>
  </div>
</template>

<style scoped lang="scss">

</style>
