# 光栅技术是计算机图形学的数据底座

- ZR有能力做作为计算机图形学的数据源
- ZR自带应用光环
- ZR设计思路借鉴过GR32,Agg,OpenCV
- ZR自然渲染引擎
- 如果只是需要Z系光栅支持技术体系,在项目引入ZR即可

# zRasterization已被pascal rewrite技术完成重构

pascal rewrite的工作步骤简单说明

- 创建模型,定义各个命名分支
- 测试模型,在独立环境模拟编译,以及与母体的合并工作
- 确定模型,当完成测试以后,未来会永久使用该模型,未来的发行和更新工作会完全以该模型运作

**被pascal rewrite技术重构后的项目从底层到高层,均可无冲突使用**


# 如何升级老项目

老项目的升级是一键完成,静待pascal writer项目的发布


# zRasterization 没有更多说明了

- 一直没空编写说明



**by.qq600585**

