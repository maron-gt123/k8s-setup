##  minecraftサーバーの構築
Minecraft Server開始に必要な初回セットアップ方法

## VMホスト<br>
+ Ubuntu22.04 LTS(cloud-init image)<br>
  + Minecraftホスト用として使用<br>
+ Minecraft Service Network Segment<br>
  + VLAN 15 Service Network (192.168.15.0/24)<br>
    + Lobby Server (192.168.15.87)<br>
    + s1 Server (192.168.15.88)<br>
    + s2 Server (192.168.15.89)<br>

## 作成フロー(VMの錬成)<br>
1. 以下は本リポジトリではサポートしません。事前構築をお願いします<br>
    + ベアメタルなProxmox環境の構築
    + VM Diskが配置可能な共有ストレージの構築
    + Snippetが配置可能な共有ストレージの構築
    + Network周りの構築
2. proxmoxのコンソール上で[mic-deploy-vm.sh](https://github.com/maron-gt123/k8s-setup-for-proxmox/blob/main/minecraft/mic-deploy-vm.sh)を実行すると、各種VMが錬成される<br>
    + 実行シーケンス
      + テンプレート用イメージVMの作成
      + テンプレート用VMを活用した運用VMを3台錬成 
      + snippetsによるCloud-initの初期設定
      + 錬成後のVM起動
      + snippets設定値の反映時間60sec
      + 各VM内で内部処理[mic-setup.sh](https://github.com/maron-gt123/k8s-setup-for-proxmox/blob/main/minecraft/minecraft-setup.sh)
      
## 錬成
* proxmoxホストコンソールで以下の処理を実施しVMを錬成

      TARGET_BRANCH=main
      /bin/bash <(curl -s https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/${TARGET_BRANCH}/minecraft/mic-deploy-vm.sh) ${TARGET_BRANCH}

##  ping確認
+ VM錬成後、pingを実行し疎通確認を実施

      for i in 7 8 9; do ping -c1 192.168.15.8$i; done 
                  
##  手動作業<br>
1. scriptでは設定できない「バックアップ用NAS設定」「crontab設定」「ipv6無効化」を別途設定
    + mount nas drive
       
       USER=[ユーザー名を明記]
       PASSWORD=[パスワードを明記]
       ssh mic-lobby-SV "sudo sh -c 'cat >> /etc/fstab << EOF
       # mount nas drive
       //nas.micnet/usbssd/mic-backup /minecraft/paper/Backups cifs noauto,user,x-systemd.automount,x-systemd.device-timeout=30,_netdev,noperm,username=$USER,password=$PASSWORD 0 0
       EOF'"
     
     
    + crontab setting
     ```
     #minecraft bukup sprict
     * 4 * * * /minecraft/paper/mic-stop.sh > /var/log/mic-stop.log 2>&1
     ```
    + ipv6 desable
     ```
    nano /etc/default/grub
    GRUB_CMDLINE_LINUX_DEFAULT="maybe-ubiquity ipv6.disable=1"
    GRUB_CMDLINE_LINUX="ipv6.disable=1"
    sudo update-grub
     ```
## VMの削除
+ VM削除に伴っては以下のscriptを実施[mic-remove-vm.sh](https://github.com/maron-gt123/proxmox-in-create/blob/main/minecraft/mic-remove-vm.sh)

## VM-deploy VM-remove時のVM-Disk lock解消
  + qmコマンドを使用したVMの錬成及びリビルド時にVM-Diskのロックが顕在化する場合あるため対処方法について記載<br>
  ```
  qm unlock {任意のVM-ID}
  ```

## VMが正しく削除されない場合
  + proxmox内のVMを一斉に削除した場合、一部ストレージ領域が残る場合があるため、適宜手動で削除を実施する必要がある。
  ```
  for host in 192.168.1.50 192.168.1.51 192.168.1.52 ; do
  # Cloudinitデータ削除
  ssh $host dmsetup remove vg01-vm--201--cloudinit
  ssh $host dmsetup remove vg01-vm--202--cloudinit
  ssh $host dmsetup remove vg01-vm--203--cloudinit
  # diskデータ削除
  ssh $host dmsetup remove vg01-vm--201--disk--0
  ssh $host dmsetup remove vg01-vm--202--disk--0
  ssh $host dmsetup remove vg01-vm--203--disk--0
  done
  ```
