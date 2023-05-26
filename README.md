# proxmox基盤をベースとした様々な仮想環境の構築<br>
自身の自宅サーバーで使用するproxmox及びkubanetesu環境について記載します。

### 前提条件<br>
* Proxmox Virtual Environment 7.3-4
  * ベアメタル3ノード運用
  * cluster構成を必須とする
* QNAP TS-253D
  * iSCSI領域として使用
* Ubuntu 22.04 LTS (cloud-init image)
  * kubernetes VMのベースとして使用
* Network Addressing
  * management Network Segment(1G) (192.168.10.0/24)
  * cluster Network Segment(1G) (192.168.1.0/24)
  * Service Network Segment(1G) (192.168.15.0/24)
  * storage Network Segment(10G) (192.168.6.0/24)
* kubernetes
  * Internal
    * Pod Network (10.128.0.0/16)
    * Service Network (10.96.0.0/16)
  * External
    * Node IP
      * Service Network (192.168.15.0-192.168.15.127)
      * Storage Network (192.168.6.0-192.168.6.127)
    * API Endpoint (192.168.6.100)
    * LoadBalancer VIP (192.168.15.60-192.168.15.80)
## proxmoxのインストール<br>
* proxmoxのインストールについては以下からインストーラーを入手[proxmox_en](https://www.proxmox.com/en/)
* インストール時の設定事項
  * country：japan
  * timezone:Asia/Tokyo
  * keymap:japan
  * E-mail:任意
  * management-interface:service-segmentと同一とする
  * hostname
    * onp-proxmox01-SV
    * onp-proxmox02-SV
    * onp-proxmox03-SV
  * gateway:192.168.15.1
  * DNS-Server:192.168.15.57
* メアメタルネットワーク設定
 * 論理構成図は以下の構成図を参照
   * [物理構成図]()
   * [論理構成図](https://github.com/maron-gt123/k8s-setup-for-proxmox/blob/main/%E8%AB%96%E7%90%86%E6%A7%8B%E6%88%90%E5%9B%B3.pdf)
 * proxmoxのbridge network設定
   * onp-proxmox01-SV
     * management：vmbr10(192.168.10.50)
     * cluster：vmbr1(192.168.1.141)
     * service：vmbr15(192.168.15.141)
     * storage：vmbr6(192.168.6.141)
   * onp-proxmox02-SV
     * cluster：vmbr1(192.168.1.142)
     * service：vmbr15(192.168.15.142)
     * storage：vmbr6(192.168.6.142)
   * onp-proxmox03-SV
     * cluster：vmbr1(192.168.1.143)
     * service：vmbr15(192.168.15.143)
     * storage：vmbr6(192.168.6.143)

## インストール後の設定
### repositoryの変更
* 以下のようにrepository情報を修正

      #proxmox-enterprise-repository disable
      cat > /etc/apt/sources.list.d/pve-enterprise.list << EOF
      #deb https://enterprise.proxmox.com/debian/pve bullseye pve-enterprise
      EOF
      
      # proxmox-No-Subscription-repository add
      cat > /etc/apt/sources.list << EOF
      deb http://ftp.debian.org/debian bullseye main contrib
      deb http://ftp.debian.org/debian bullseye-updates main contrib

      # PVE pve-no-subscription repository provided by proxmox.com,
      # NOT recommended for production use
      deb http://download.proxmox.com/debian/pve bullseye pve-no-subscription
      
      # security updates
      deb http://security.debian.org/debian-security bullseye-security main contrib
      EOF

### MegaRAIDドライバの導入
* 以下scriptでMegaRAIDドライバを導入

      # ---region---
      MEGARAIDURL=https://docs.broadcom.com/docs-and-downloads/raid-controllers/raid-controllers-common-files/8-07-14_MegaCLI.zip
      # ------------
      
      # zip install
      apt install libncurses5 unzip alien
      
      # wget Mega-CLI
      wget $MEGARAIDURL
      
      # unzip
      unzip 8-07-14_MegaCLI.zip

      # create debian package
      cd Linux
      alien MegaCli-8.07.14-1.noarch.rpm

      # install debian package
      dpkg -i megacli_8.07.14-2_all.deb
      
      # run
      /opt/MegaRAID/MegaCli/MegaCli64 -h
      /opt/MegaRAID/MegaCli/MegaCli64 -AdpCount
      /opt/MegaRAID/MegaCli/MegaCli64 -AdpAllInfo -aALL
      
      # echo
      echo "RAID情報の確認が取れない場合は以下参照(https://gist.github.com/fxkraus/595ab82e07cd6f8e057d31bc0bc5e779)"

### NFSサーバをproxmoxに導入
* onp-proxmox02及びonp-proxmxo03にNFSサーバを構築
  * onp-proxmox02
    * snippets及びubuntu22.04のOSインストールデータ格納
  * onp-proxmox03
    * backup格納用

          # nfs-kernel-serverをインストール
          ssh prox02 apt-get install nfs-kernel-server
          ssh prox03 apt-get install nfs-kernel-server
          
          # exports設定
          ssh prox02 cat >> /etc/exports <<EOF
          /mnt/pve/prox02 192.168.6.0/24(rw,sync,no_all_squash,no_root_squash,no_subtree_check)
          EOF
          ssh prox03 cat >> /etc/exports <<EOF
          /mnt/pve/prox03 192.168.6.0/24(rw,sync,no_all_squash,no_root_squash,no_subtree_check)
          EOF
