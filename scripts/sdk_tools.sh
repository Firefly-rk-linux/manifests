#!/bin/bash

#source bootloader-arm64/scripts/envsetup.sh

OPTIONS="${@:-allff}"
UPGRADE_PATH=./


function log() {
    local format="$1"
    shift
    printf -- "$format\n" "$@" >&2
}

function do_with_retry()
{
        local count=$1
        shift
        until "$@"; do
                ((count--))
                ((count==0)) && break
                log "Failed, Try again"
                sleep 5
        done

        if ((count==0)); then
                log "Failed, Reached Max Retry Times"
                return 1
        else
                log "Success"
        fi
}

function run() {
        if [ "$1" == "-i" ]; then
                shift
                max_try_time=1
                log "I: Running command with ignore error: %s" "$*"
        else
                max_try_time=3
                log "I: Running command: %s" "$*"
        fi
        do_with_retry ${max_try_time} "$@"
}


function build_release()
{
    if [ ! -f ".repo/manifest.xml" ]; then
        log ".repo/manifest.xml: No such file or directory"
        log "Failed"
        exit 1
    fi
    sdk_name=$(realpath .repo/manifest.xml  |awk -F '/' '{print $(NF) }'| awk -F '.xml' '{print $(1) }')

    rm -rf linux_sdk_tar
    if [ ! -d linux_sdk ];then
        mkdir -p linux_sdk_tar
    fi

    log "I: Running command: tar cf -  .repo/ | split -b 4000M - linux_sdk_tar/${sdk_name}.sdk.split -d -a 2 --verbose"
    tar cf -  .repo/ | split -b 4000M - linux_sdk_tar/${sdk_name}.sdk.split -d -a 2 --verbose

    # Create MD5
    log "I: Running command: ls ${sdk_name}.sdk.split* |sort | xargs md5sum | tee md5sum.txt"
    ls linux_sdk_tar/${sdk_name}.sdk.split* |sort | xargs md5sum | tee md5sum.txt

    # create README
    README

    rm -rf $sdk_name
    if [ ! -d linux_sdk ];then
        mkdir -p $sdk_name
    fi

    ls | grep -v $sdk_name| xargs -I {} mv {} $sdk_name
}


function do_check_md5()
{
    log "Start checking MD5"
    if [ ! -f "md5sum.txt" ]; then
        log ".md5sum.txt: No such file or directory"
        log "Failed"
        exit 1
    fi

    while read line
    do
        MD5=$(echo $line | awk -F ' ' '{print $1}')
        MD5_FILE=$(echo $line | awk -F ' ' '{print $2}')


        tmp=`md5sum $MD5_FILE | awk -F ' ' '{print $1}'`

        if [ "$tmp" != "$MD5" ];then
            log "$MD5_FILE: $tmp != $MD5 check MD5 error"
            exit 1
        else
            log "$MD5_FILE: check MD5 success"
        fi
    done < md5sum.txt
}

function README()
{
README_FILE="README_ZH.txt"
cat << EOF > ${README_FILE}
 _____ _           __ _
|  ___(_)_ __ ___ / _| |_   _
| |_  | | '__/ _ \ |_| | | | |
|  _| | | | |  __/  _| | |_| |
|_|   |_|_|  \___|_| |_|\__, |
                        |___/

* 官网 www.t-firefly.com  |  www.t-chip.com.cn
* 技术支持 service@t-firefly.com
* 开源社区 https://dev.t-firefly.com/portal.php?mod=topic&topicid=11

解压和更新SDK说明：

第一次使用SDK需执行3个步骤，如果是后续想更新SDK，只需执行第3步进行网络更新即可

1. 解压SDK

chmod +x $0

创建一个目录以存放SDK：比如我现在这个是3588的SDK，我想解压到上一层文件夹，避免污染当前目录

mkdir ../firefly_rk3588_SDK
$0 --unpack -C ../firefly_rk3588_SDK


2. 还原工作目录

选择刚才解压后的目录

$0 --sync -C ../firefly_rk3588_SDK

可以使用上面脚本执行或者手动执行命令，选择其中一种即可

# 进入刚刚解压后的目录，比如我这里是../firefly_rk3588_SDK
cd ../firefly_rk3588_SDK
.repo/repo/repo sync -l
.repo/repo/repo start firefly --all


3. 更新SDK

前面2个步骤只在第一次解压SDK时执行，后续更新SDK只需进入SDK目录执行第3步骤，进行网络更新

.repo/repo/repo sync -c --no-tags

EOF

README_FILE="README_EN.txt"
cat << EOF > ${README_FILE}
 _____ _           __ _
|  ___(_)_ __ ___ / _| |_   _
| |_  | | '__/ _ \ |_| | | | |
|  _| | | | |  __/  _| | |_| |
|_|   |_|_|  \___|_| |_|\__, |
                        |___/

* Official website https://en.t-firefly.com/  |  www.t-chip.com.cn
* Technical Support service@t-firefly.com
* Forums https://bbs.t-firefly.com/forum.php?mod=forumdisplay&fid=100


Instructions for decompressing and updating the SDK:

The first time you use the SDK, you need to perform 3 steps. If you want to update the SDK later, you only need to perform step 3 to update the network.

1. Unpack the SDK

chmod +x $0

mkdir ../firefly_sdk


Create a directory to store the SDK: For example, my current SDK is 3588, and I want to decompress it to the upper folder to avoid polluting the current directory

mkdir ../firefly_rk3588_SDK
$0 --unpack -C ../firefly_rk3588_SDK


2. Restore the working directory

Select the directory you just decompressed

$0 --sync -C ../firefly_rk3588_SDK


You can use the above script to execute or manually execute the command, choose one of them


# Enter the directory just after decompression, for example, here is ../firefly_rk3588_SDK
cd ../firefly_rk3588_SDK
.repo/repo/repo sync -l
.repo/repo/repo start firefly --all


3. Update the SDK

The first two steps are only performed when the SDK is decompressed for the first time, and the subsequent update of the SDK only needs to perform the third step for network update

.repo/repo/repo sync -c --no-tags

EOF
}

function do_unpack()
{
    log "Unpack linux sdk:"
    if [ ! -f "md5sum.txt" ]; then
        log ".md5sum.txt: No such file or directory"
        log "Failed"
        exit 1
    fi

    cat md5sum.txt  |awk -F ' ' '{print $2}'| xargs cat | tar -xv -C $UPGRADE_PATH

    if [ "$?" = "0" ];then
        log "Uppack linux sdk success!"
    else
        log "Uppack linux sdk fail!"
    fi


    echo -e "\n你可以查看firefly wiki，以获取SDK更多使用和开发信息:"
    echo -e "You can check the firefly wiki for more usage and development information of the SDK:"
    echo -e "EN: https://www.t-firefly.com/wiki"
    echo -e "EN: https://www.t-firefly.com/wiki"
}

function f_sync_local()
{
    if [ ! -f ".repo/repo/repo" ]; then
        log ".repo/repo/repo: No such file or directory"
        log "Failed"
        exit 1
    fi

    run .repo/repo/repo sync -l
    run .repo/repo/repo start firefly --all
}

function usage()
{
    echo -e "Usage:"
    echo -e "$0 unpack \t unpack linux SDK"
    #echo -e "$0 sync_local \t only update working tree, don't fetch"
}


# for option in ${OPTIONS}; do
#     case $option in
#         release) build_release;;
#         sync_local) f_sync_local;;
#         check_md5) do_check_md5;;
#         unpack) do_check_md5; do_unpack;;
#         *) usage ;;
# 	esac
# done

function show_help(){

cat << EOF
$0
参数说明：
  -h, --help:           打印帮助信息
  -p, --release         打包SDK
  -C, --directory=DIR   output directory
  -x, --unpack          unpack SDK
  -c, --check_md5       check md5
  --sync                sync sdk

e.g.

# unpack sdk
$0 --unpack

# pack sdk
$0 --release
EOF

}

getopt_cmd=$(getopt -o xC:pch --long help,release,unpack,directory::,check_md5,sync -n $(basename $0) -- "$@")
[ $? -ne 0 ] && show_help && exit 1
eval set -- "$getopt_cmd"
while [ -n "$1" ]
do
    case "$1" in
        -C|--directory)
            # unpack directory
            UPGRADE_PATH="$2"
            shift 2;;
        -x|--unpack)
            task=unpack
            shift 1;;
        -p|--release)
            task=release
            shift 1;;
        -c|--check_md5)
            task=check_md5
            shift 1;;
        --sync)
            task=sync
            shift 1;;
        -h|--help)
            show_help
            exit 0
            ;;
        --)
            shift
            break ;;
        ?|*)
            show_help
            exit 0
    esac
done


if [ ! -d "$UPGRADE_PATH" ]; then
    echo "directory $UPGRADE_PATH not exit"
    exit 1
fi

case $task in
    unpack)
        do_check_md5
        rm -rf $UPGRADE_PATH/.repo
        do_unpack
        ;;
    sync)
        run pushd $UPGRADE_PATH
        f_sync_local
        run pushd
        ;;
    check_md5)
        do_check_md5
        :
        ;;
    release)
        build_release
        ;;
    ?|*)
        echo "no task"
esac

