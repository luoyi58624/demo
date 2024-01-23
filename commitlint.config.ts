/*
 * @Description: commit-msg提交信息格式规范
 *
 * commit-msg格式: <type>(scope?): <subject>         注意: 冒号:和<subject>之间需要一个空格
 *  - type: 用于表明我们这次提交的改动类型，是新增了功能？还是修改了测试代码？又或者是更新了文档？
 * 	  - feat!、fix!: 重大更新、或破坏式升级、修复bug  	- release时将自动增加第一个版本号
 *    - feat: 新特性、新功能  					    - release时将自动增加第二个版本号
 *    - fix: 修改bug    				            - release时将自动增加第三个版本号(以下所有类型提交执行release时都只会更新小版本)
 *    - perf: 优化相关，比如提升性能、体验
 *    - chore: 其他修改, 比如改变构建流程、或者增加依赖库、工具等
 *    - docs: 仅文档新增/改动 （documentation）
 *    - build: 编译相关的修改，例如发布版本、对项目构建或者依赖的改动
 *    - ci: 持续集成修改
 *    - optimize: 优化构建工具或运行时性能
 *    - refactor: 代码重构
 *    - revert: 回滚到上一个版本
 *    - style: 代码格式修改, 注意不是 css 修改
 *    - test: 测试用例修改
 *    - update: 更新某功能
 *  - scope：一个可选的修改范围。用于标识此次提交主要涉及到代码中哪个模块。
 *  - Subject：一句话描述此次提交的主要内容，做到言简意赅
 */
const type = [
	'feat',
	'fix',
	'perf',
	'chore',
	'docs',
	'build',
	'ci',
	'optimize',
	'refactor',
	'revert',
	'style',
	'test',
	'update'
]
export default {
	extends: ['@commitlint/config-conventional'],
	rules: {
		'type-empty': [2, 'never'], // <type> 不能为空
		'type-enum': [2, 'always', [...type]], // <type> 规定使用类型
		'type-case': [0],
		'scope-empty': [0], // <scope> 可为空
		'subject-empty': [2, 'never'], // <subject> 不能为空 (默认)
		'subject-full-stop': [2, 'never', '.'], // <subject> 结尾不加'.'
		'subject-case': [0],
		'header-max-length': [2, 'always', 72], // header最大72个字符
		'body-leading-blank': [1, 'always'], // body上面要有换行
		'footer-leading-blank': [1, 'always'] // footer上面要有换行
	}
}
