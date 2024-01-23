<script setup lang="ts">
const router = useRouter()
const route = useRoute()
let noLogin = false

if (noLogin) {
	router
		.replace({
			name: 'Login',
			query: { redirect: route.fullPath }
		})
		.then(() => {})
} else {
	router.replace('/404').then(() => {})
}
</script>

<template>
	<div></div>
</template>

<style scoped lang="scss"></style>
