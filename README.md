LustreTools
=========================
[![TeamCity CodeBetter](https://img.shields.io/teamcity/codebetter/bt428.svg?maxAge=2592000)]()
[![Packagist](https://img.shields.io/packagist/v/symfony/symfony.svg?maxAge=2592000)]()
[![Yii2](https://img.shields.io/badge/Powered_by-multexu Framework-green.svg?style=flat)]()
![Progress](http://progressed.io/bar/95?title=completed )

@(LustreTools)[Lustre自动化工具│HELP│AutoLustre]

**LustreTools** 是在[MULTEXU](https://github.com/ShijunDeng/multexu)基础上开发的，特别针对Lustre分布式文件系统设计的自动编译、安装、部署、测试、控制和监测的工具套件，包括以下功能：
 
- **自动认证** ：节点在一个局域网，在其中指定一台主机做为管理机，其它主机做为被管理机，为以后维护的便利性，要求实现管理机无需密码，直接登录被管理机；
- **自动编译** ：自动完成Lustre的编译工作，包括编译带有Lustre补丁的Linux内核，Lustre文件系统的服务端和客户端；
- **自动安装** ：自动安装编译生成的Linux内核、lustre文件系统；
- **自动部署** ：自动部署lustre文件系统；
- **统一控制** ：采用MULTEXU基础套件进行统一管理控制的工具；
- **自动测试** ：自动测试Lustre的性能，生成测试报告；
- **性能监测** ：使用Lustre Monitoring Tool监测lustre的运行情况；

**说明**：LustreTools针对的是CentOS7（Linux kernel 3.10.0-327.el7.x86_64）和Lustre2.8.0，其它版本的系统使用本工具可能需要解决一些兼容性问题。另外，CentOS7在安装过程中，选择的版本和安装配置不同，也可能导致一些包的依赖性问题，因此建议CentOS7的安装过程参照视频教程进行安装。LustreTools自带Lustre2.8.0全套安装文件，参见[LustreTools](http://pan.baidu.com/s/1gfDkj7P)下载。

-------------------

[参考文档]

# LustreTools设计

LustreTools主要是采用shell和python脚本编写的自动化控制套件

## 主要文件概览
	LustreTools
	│  README.md
	│
	├─batch
	│  ├─authorize
	│  │      distribute.sh
	│  │      execuse.sh
	│  │      nodes_authorize.sh
	│  │      nodes_authorize.sh.origin
	│  │      start_authorize.sh
	│  │
	│  ├─build
	│  │      build_lustre_client.sh
	│  │      build_lustre_server.sh
	│  │      build_newkernel.sh
	│  │      README
	│  │      _patch_metric.sh
	│  │
	│  ├─config
	│  │      hosts
	│  │      hostsfile
	│  │      hosts_table
	│  │      nodes_all.out
	│  │      nodes_authorize.out
	│  │      nodes_client.out
	│  │      nodes_oss.out
	│  │      nodes_server.out
	│  │      README.md
	│  │
	│  ├─config.bake
	│  │      hostfile
	│  │      hosts
	│  │      nodes_all.out
	│  │      nodes_authorize.out
	│  │      nodes_client.out
	│  │      nodes_oss.out
	│  │      nodes_server.out
	│  │
	│  ├─ctrl
	│  │      auto_lustre_2.8.0.sh
	│  │      help_doc.txt
	│  │      multexu.sh
	│  │      multexu_lib.sh
	│  │      multexu_ssh.sh
	│  │      __init.sh
	│  │
	│  ├─deploy
	│  │      auto_lustre2.8.0_deploy.sh
	│  │      _configure_ossnode.sh
	│  │      __auto_parted.sh
	│  │      __configure_clientnode.sh
	│  │      __configure_mdsnode.sh
	│  │      __configure_ossnode.sh
	│  │
	│  ├─install
	│  │      auto_lustre2.8.0_install.sh
	│  │      lustre_install_client.sh
	│  │      lustre_install_newkernel.sh
	│  │      lustre_install_pre.sh
	│  │      lustre_install_server.sh
	│  │
	│  ├─lmt
	│  │      lmt_install.sh
	│  │      _cerebro_install.sh
	│  │      _configure_cerebro_conf.sh
	│  │      _host_conf.sh
	│  │      _lmt_install.sh
	│  │      _mysql_install.sh
	│  │
	│  ├─test
	│  │  │  auto_test_fio.sh
	│  │  │  clear_var_log_messages.sh
	│  │  │  fio_install.sh
	│  │  │  _test_exe.sh
	│  │  │
	│  │  └─testResult
	│  ├─tool
	│  │      molokai_install.sh
	│  │      set_display.sh
	│  │
	│  └─uninstall
	│          auto_lustre2.8.0_uninstall.sh
	│          lustre_uninstall_client.sh
	│          lustre_uninstall_newkernel.sh
	│          lustre_uninstall_pre.sh
	│          lustre_uninstall_server.sh
	│
	├─code
	├─document
	├─source
	│  ├─build
	│  │  └─metric
	│  │      ├─Makefile
	│  │      └─metric-tests
	│  ├─install
	│  ├─lmt
	│  └─tool
	└─testResult
	    └─fio

## 功能说明
	LustreTools
	├─batch：脚本
	│  ├─authorize：认证
	│  ├─build：编译
	│  ├─config：配置文件
	│  ├─config.bake：配置文件备份
	│  ├─ctrl：MULTEXU工具套件，统一控制
	│  ├─deploy：部署
	│  ├─install：安装
	│  ├─lmt：Lustre Monitoring Tool安装
	│  ├─test：测试
	│  │  └─testResult：测试结果
	│  ├─uninstall：卸载工具		
	│  └─tool：一些常用的工具
	├─code：代码、补丁
	├─source：LustreTools用到的rpm包、资源文件
	│	├─build：编译阶段用到的包
	│	├─install：安装阶段用到的包存放目录，通常是build阶段产生的
	│	├─lmt：Lustre Monitoring Tool相关资源
	│	└─tool：测试工具安装文件
	├─document：常用的文档、演示、PPT等
	└─testResult：测试结果存放目录
			
#LustreTools架构

![image](https://github.com/ShijunDeng/LustreTools/blob/master/source/image/architecture.png)

**说明**

- **Lustre文件系统**
	
	>LustreTools要进行控制的文件系统，LustreTools将在这些节点上根据配置信息，安装Lustre文件系统，进行部署、测试、监控等工作。

- **控制节点**

	>控制节点是一个独立于Lustre文件系统节点之外的节点，LustreTools的脚本主要在控制节点上运行，实现Lustre自动化的编译、安装、部署、测试工作。控制节点首先通过批量配置与Lustre文件系统节点、编译节点的信任关系,实现在这些节点上的免密码登录。控制节点在实现免密码登陆后，通过ssh协议远程执行控制命令执行任务，并周期性检测任务的任务的完成情况。

- **编译节点**

	>编译节点也是一个独立于Lustre文件系统节点之外的节点，LustreTools将源文件发送到该节点，控制该节点进行编译工作（Linux内核、Lustre文件系统），当控制节点检测到编译任务完成，就取回编译生成的rpm包，供安装阶段使用。在使用LustreTools时，需要进行编译工作，就在nodes_authorize.out中加上编译节点的ip地址。LustreTools默认Lustre2.8全部的安装文件，可以不经过编译阶段，直接用于安装。
	
# LustreTools使用

注：根据lustre和Linux kernel的版本，需要适当对工具进行定制和修改，参见源代码中的说明；编译、安装、部署、测试工具中自带的lustre和Linux kernel，除了配置节点IP之外，不需要任何更改；

##使用authorize认证

说明：在一个局域网，在其中指定一台主机做为管理机，其它主机做为被管理机，为以后维护的便利性，要求实现管理机无需密码，直接登录被管理机；假设指定controller作为控制节点，通过shell脚本，实现一次执行，批量配置管理机与被管理机的信任关系，实现管理机免密码登录被管理机。
使用步骤：

    1. 在config文件的nodes_authorize.out中配置好要管理的主机的ip地址，一个ip占据一行，不要包括其它任何无关信息；
    2. 运行 sh start_authorize.sh，根据提示操作
		[root@CentOS1 authorize]# sh ClientAuthorize.sh
		Generating public/private rsa key pair.
		#type Enter directly
		Enter file in which to save the key (/root/.ssh/id_rsa)：
		Created directory '/root/.ssh'.
		#type Enter directly，make empty passward
		Enter passphrase (empty for no passphrase)：
		Enter same passphrase again：
		Your identification has been saved in /root/.ssh/id_rsa.
		Your public key has been saved in /root/.ssh/id_rsa.pub.
		The key fingerprint is：
		6d：bc：5c：f8：32：bf：ee：4a：fe：bf：be：76：8d：29：38：aa root@CentOS1
		The key's randomart image is：
		|                 |
		|                 |
		|                 |
		|         o .     |
		|        S = .    |
		|         o +     |
		|          *..  o.|
		|         oo+. + o| 
		|      E...o***=+ | 
		#the warning occurs because of the option StrictHostKeyChecking=no，just ignore it
		Warning： Permanently added '192.168.10.3' (RSA) to the list of known hosts.
		#Because trust has not yet been established， so still need a password
		root@192.168.122.101's password：
		ServerAuthorize.sh                                                                            100%  664     0.7KB/s   00：00
		Warning： Permanently added '192.168.10.4' (RSA) to the list of known hosts.
		root@192.168.122.102's password：
		ServerAuthorize.sh                                                                            100%  664     0.7KB/s   00：00
		Warning： Permanently added '192.168.10.5' (RSA) to the list of known hosts.
		root@192.168.122.103's password：
		ServerAuthorize.sh                                                                            100%  664     0.7KB/s   00：00
		#Start， after the completion of distribution in each managed machine configuration script execution
		root@192.168.122.101's password：
		root@192.168.122.102's password：
		root@192.168.122.103's password：
 	3. 所有输入完毕后等待节点重启


##使用build执行自动编译

说明：build主要对Linux内核、lustre源码的源码进行编译，生成用于安装的rpm包，在编译节点上进行，生成的rpm文件可以复制到同构节点中直接使用。

 - 编译内核
 
		1. sh build/build_newkernel.sh #进行内核编译，如需要对内核补丁和配置，请参照注释修改脚本中的代码	
		2. rpm -ivh --force kernel-3.10.0_3.10.0_327.3.1.el7_lustre.x86_64*.rpm #安装内核	
		3. /sbin/new-kernel-pkg --package kernel --mkinitrd --dracut --depmod --install 3.10.0-3.10.0-327.3.1.el7_lustre.x86_64
		4. reboot
	
	注：一般内核的编译只需要进行一次就行了，在Lustre的开发中主要是对文件系统的编译，只有修改过内核代码后才进行内核的编译安装
 
- 编译Lustre服务端

		sh build/build_lustre_server.sh [--skip_install_dependency=0|1]

	参数选项:

		--skip_install_dependency=0或者缺省表示先安装编译工作需要的依赖，再进行编译工作；
		--skip_install_dependency=1表示不安装依赖，直接进行编译。

	在进行开发时，编译工作需要多次进行，依赖安装需要很长时间，且只需要在第一次进行就行了，因此在经过一次编译后，后续的开发编译可以省略安装依赖的环节以加速编译，节省时间

- 编译Lustre服务端

	参见编译Lustre服务端


##使用install安装

说明：install主要进行安装操作，只需要运行auto_lustre2.8.0_install.sh即可，其它脚本均为自动调用

- 安装Lustre文件系统

    	sh install/auto_lustre2.8.0_install.sh [skip_install_kernel=0|1]

	参数选项:

		--skip_install_kernel=0 或者缺省 表示先安装内核，再安装Lustre文件系统；
		--skip_install_kernel=1 表示不安装内核，直接安装Lustre文件系统。

	--skip_install_kernel主要应用于开发阶段，需要反复进行修改源码、编译、安装、测试流程，而安装过程包含安装内核、安装文件系统两个阶段，通常安装内核需要很长时间，如果未对内核进行修改，内核的重复安装实际是不必要的。在虚拟机中进行开发时，可以在节点中先安装好内核，并将这些已安装内核的节点备份，当要文件系统编译好之后，直接将备份的节点拷贝一份，在这些新拷贝的节点上直接安装新的文件系统，而不必安装内核，这样可以加速开发进程。在实际应用节点，也即在全新的节点上安装Lustre文件系统时，省略该选项或者指定为0。
	
##使用deploy部署

说明：自动部署文件系统，用法实例

- 部署Lustre文件系统

		sh deploy/auto_lustre2.8.0_deploy.sh --mdsnode=192.168.122.140 --devname=/dev/sda --index=3 

	参数选项:

		--mdsnode mdsnode服务器的ip地址
		--devname 设备名称，将在该设备上格式化进行文件系统安装
		--index 分区的index，例如lustre将要挂在到/dev/sda3，则这里的index为3

	另外，还需要在config文件夹下进行相关的ip地址配置

		nodes_client.out：所有client端的ip地址，一个ip占据一行
		nodes_oss.out：所有oss端的ip地址，一个ip占据一行
		nodes_server.out：oss && mdsnode一起的ip地址，一个ip占据一行


##使用lmt安装Lustre Monitoring Tool
说明：安装Lustre Monitoring Tool，用法实例

- 安装Lustre Monitoring Tool

		sh lmt/lmt_install.sh --mdsnode=192.168.122.140 --lmt_mgnode=192.168.122.141

	参数选项:

		--mdsnode为mdsnode服务器的ip地址
		--lmt_mgnode为lmt管理节点ip地址,缺省情况下为当前节点
	
- 参见[lmt配置](https://github.com/ShijunDeng/LustreTools/blob/master/document/lmt.docx)配置相应的/etc/hosts、/etc/hostfile、/etc/cerebro.conf文件后才能正常使用该命令

##使用test测试
说明：进行测试，可以根据需要修改auto_test_fio.sh中的参数配置，详细使用方法见auto_test_fio.sh中的注释

	 sh test/auto_test_fio.sh --random="-rwmixread=50"
参数选项:

		--random参数指定针对random读写方式的一些特殊添加命令,只对random读写方式生效,实例中指定了读写的控制比例

参见[Fio官方文档](https://linux.die.net/man/1/fio)，结合本脚本使用，参见[FIO测试自动化分析](https://github.com/ShijunDeng/luspinf/tree/master/batch/LuspinfAnalysis)生成测试报告。

##使用tool
说明：tool中集成一些常见的工具类脚本,使用说明
	 
	sh test/set_display.sh 1440 900 #设置分辨率为1440*900

##使用MULTEXU进行统一控制
说明：为便于测试过程中的管理中的管理，使用MULTEXU进行统一控制，具体使用方法见 [MULTEXU](https://github.com/ShijunDeng/multexu)。另外, 参见 [nrcmd.txt](https://github.com/ShijunDeng/LustreTools/blob/master/document/nrcmd.txt) 中常见的控制命令

##关于开发阶段全自动化
鉴于Lustre开发系统的复杂性，使用该脚本前，一定先仔细阅读auto_lustre_2.8.0.sh脚本，并根据注释做定制。

说明：在开发阶段，我们最希望，修改完Lustre文件系统的代码后，脚本能自动的进行编译、安装、部署等工作，LustreTools提供这一功能。在完全符合文档说明要求的情况下，可以使用全自动化无监督的完成编译、安装、部署、测试、lmt安装工作，大致流程是（该流程对手动的使用LustreTools也具有一定指导意义）：

- 用于开发的物理机（1台）配置要求
	
		硬盘	300GB以上，内存32GB以上，可以联网，CPU越快越好，物理机安装CenOS7 和KVM虚拟机（安装过程参见/document/centosos安装过程.mp4视频）

- 前期准备工作（一次）
	1. 准备CentOS7镜像文件，使用kvm虚拟机安装（安装过程参见/document/centosos安装过程.mp4视频），并对节点进行配置，设置IP、根据个人需求配置开发环境等，后面的节点均是根据本次安装的节点进行克隆的而来；	
	2. 克隆足够数量的虚拟机节点，启动所有节点并根据需要进行修改，主要是配置各个节点的IP，确定控制节点、编译节点、文件系统节点，也即克隆的节点的角色（控制节点可以选择一个克隆节点作为控制节点，或者使用物理主机作为控制节点）；	
	3. 节点的角色确定后，根据节点IP配置config下的.out文件；
	4. 在控制节点上使用authorize认证各个节点，让控制节点可以免密码登陆各个节点并执行任何命令；
	5. 备份上述节点，或者：在编译节点上使用build编译生成内核，在各个节点上安装内核后再备份。如何备份虚拟机节点取决于开发过程中是否需要修改内核。LustreTools本身也提供编译好的内核文件，配置与稳定要求完全相符合的情况下可以直接使用；
	6. Lustre文件系统的源码rpm包，和其它工具（FIO、lmt等等）的安装包，LustreTools默认提供Lustre2.8.0源码包以及编译好的安装包；


- 修改代码（开发阶段）

	保存修改后的代码文件到source/build，并同时修改batch/build/_patch_metric.sh，LustreTools通过_patch_metric.sh修改Lustre源码，运行脚本：sh ctrl/auto_lustre_2.8.0.sh，之后的工作全部自动化完成；一定要注意修改的代码是在这里被替换到内核或者Lustre元代中去的，请参照关于metric示例对应修改相关的文件。

- auto_lustre_2.8.0.sh 工作流程
	1. LustreTools从备份的虚拟机节点中恢复新的节点（全新节点或者安装了Lustre特定内核的节点）；
	2. 启动各节点并等待，知道各个节点完全启动并ping通；
	3. 删除LustreTools中旧的安装包，删除编译节点上旧的文件，发送新文件（目前是整个LustreTools）到编译节点；
	4. 启动编译工作，并等待编译完成，取回编译生成文件；
	5. 分发编译生成的文件到最新恢复新的节点中；
	6. 开发安装、部署、测试等后续工作；
	7. 完毕；



- auto_lustre_2.8.0.sh 使用说明

		sh ctrl/auto_lustre_2.8.0.sh [--skip_build_kernel=0|1][--goto_compile=0|1][--only_pre=0|1][--install_lmt=0|1]

	参数选项:

		--skip_build_kernel ：是否需要编译新内核。如果是首次运行该脚本或者对内核做过修改，那么编译节点需要先编译内核，并自动安装新内核后，再开始文件系统的编译工作；如果不涉及内核的修改，可以省略该选项或者设置为0。skip_build_kernel默认值为1
		--goto_compile与--only_pre ： 鉴于虚拟机节点复制需要5-10分钟或者更长时间，为了避免代码修改完毕后运行脚本需要长时间等待情况，可以在空余时间指定--only_pre=1，这样只恢复备份的节点，而不进行后续编译、安装、部署等工作，在代码修改完毕后指定-- goto_compile=1直接进行编译、安装、部署等工作，而不需要恢复节点的过程，达到节约时间的目的。默认值为0
		--install_lmt ： 是否安装lmt工具；默认值为1


## 反馈与建议
- QQ：946057490
- 邮箱：<dengshijun1992@gmail.com> <sjdeng@hust.edu.cn>

---------
感谢您阅读这份帮助文档。