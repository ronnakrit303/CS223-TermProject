# 08 — QA Test Cases & Cloud Administration Guide (อ้างอิงตำราอาจารย์กษิดิศ บทที่ ๑)

> **CS223 Term Project — OpenStack 2026.1 Multinode Deployment (`grp25`)**  
> **เอกสาร:** แผนการทดสอบระบบ (Test Cases Matrix), ขั้นตอนสาธิตการใช้งานและงาน Admin ตาม [ตำราอาจารย์ บทที่ ๑](https://kasidit.github.io/OpenStack-Tutorial-0.01/) สำหรับสมาชิกคนที่ 3  
> **อ้างอิงสภาพแวดล้อมจริง:** `controller01` (`192.168.1.160`) + `compute01` (`192.168.1.7`) บน Ubuntu Server 24.04.3 LTS

[← Handover](07-handover.md) · [README](../README.md) · [Final Report & Demo Script →](09-final-report-draft-and-demo-script.md)

---

## 1. สรุปการคลี่คลายโจทย์จากเอกสาร Feasibility (15 พ.ย. → 17 พ.ย. 2026)

หากอาจารย์ถามตอนนำเสนอความคืบหน้า (18 พ.ย.) ว่ากลุ่มแก้ปัญหาข้อจำกัดของ **Nested OpenStack (รัน OpenStack ซ้อนบน OpenStack ของอาจารย์)** อย่างไร ให้ใช้ตารางนี้ตอบได้เลย:

| รหัสปัญหาเดิม (15 พ.ย.) | ประเด็นที่กังวลตอนวางแผน | วิธีที่กลุ่มแก้สำเร็จจริงในระบบ (17 พ.ย.) | สถานะปัจจุบัน |
| :--- | :--- | :--- | :---: |
| **C1 / D1 (Sizing & Disk)** | Flavor มี Root Disk เล็ก (24–30 GB) กลัวเก็บ Container Images ไม่พอ | สร้าง Ubuntu VM 2 เครื่อง (4 vCPU, RAM ~9.7 GiB) มี Root Disk 30 GB และ **Attach Volume แยกอีกเครื่องละ 40 GB Format `ext4` ไป Mount ที่ `/var/lib/docker`** | ✅ **VERIFIED PASS** |
| **H1 (Nested KVM)** | `compute01` เครื่องใหม่จะเปิดใช้ `/dev/kvm` และรัน VM ซ้อนได้จริงไหม? | ตรวจพบ `vmx` และ `/dev/kvm` บน `compute01` ตั้งค่า `nova_compute_virt_type: "kvm"` และ **Boot VM `cs223-test-vm` (CirrOS) ขึ้นสถานะ `ACTIVE` สำเร็จแล้ว** | ✅ **VERIFIED PASS** |
| **N1 (Inner VIP & Port Security)** | ถ้าใช้ Floating VIP (Keepalived/HAProxy) บนวงแลนของอาจารย์ จะติด Neutron Port Security (Anti-spoofing) | ออกแบบเป็น **Single-Controller Non-HA** ตั้ง `kolla_internal_vip_address: "192.168.1.160"` (ใช้ IP จริงของ `controller01`) และปิด `haproxy`, `keepalived`, `proxysql` จึงไม่ต้องทำ VIP Spoofing บนพอร์ตชั้นนอก | ✅ **VERIFIED PASS** |
| **N2 (Inner Overlay & MTU)** | VXLAN ข้ามเครื่องระหว่าง `controller01` กับ `compute01` จะติดปัญหา MTU ของวงแลนชั้นนอกไหม? | วงแลนชั้นนอก (`localnet1`) มี MTU `1450` จึงตั้งค่า Override `global_physnet_mtu = 1450` และ `path_mtu = 1450` ทำให้เครือข่าย VXLAN ชั้นในลด MTU เหลือ **`1400`** และแจก IP ผ่าน DHCP ข้ามโฮสต์สำเร็จ | ✅ **VERIFIED PASS** |
| **N3 (External Network / `br-ex`)** | ถ้าเอา `ens3` ไปผูก `br-ex` จะทำให้ SSH เข้าเครื่องไม่ได้ | สร้าง Linux Dummy Interface (`dummy0`) บน `controller01` ไปผูกกับ `br-ex` เพื่อรักษา `ens3` **และต่อยอดตั้งค่า `ext-net` (`172.24.4.0/24`), กำหนด IP `172.24.4.1/24` บน `br-ex` + `iptables MASQUERADE` ออก `ens3` แบบ Runtime จนผูก Floating IP `172.24.4.122` และ `ping 8.8.8.8` สำเร็จแล้ว** *(หมายเหตุ: ค่า Host NAT เป็น Runtime ไม่คงอยู่หลัง Reboot)* | ✅ **VERIFIED PASS (Runtime NAT)** |
| **S1 (Software Release)** | ต้องใช้เวอร์ชันที่ไม่ตีกันระหว่าง OS, Ansible และ Kolla | ใช้ชุดที่เข้ากันทั้งหมด: **Ubuntu 24.04.3 LTS + OpenStack 2026.1 + Kolla Ansible `22.2.1.dev36` (`stable/2026.1`) + Ansible Core `2.19.15`** และแยก Venv ของ Kolla ออกจาก OpenStack CLI | ✅ **VERIFIED PASS** |

---

## 2. การเทียบเคียงเนื้อหา "บทที่ ๑ การใช้งานโอเพนสแตค" ของอาจารย์ กับระบบของเรา

อาจารย์กษิดิศเขียนตำรา [บทที่ ๑ การใช้งานโอเพนสแตค](https://kasidit.github.io/OpenStack-Tutorial-0.01/) ไว้เป็นแนวทางหลัก ซึ่งบางหัวข้อในตำราใช้ฟีเจอร์ที่ระบบของเราปิดไว้ (เช่น Cinder Volume และ Provider Network ออกเน็ต) คนที่ 3 จึงต้องรู้ว่า **หัวข้อไหนทำได้เหมือนตำรา 100%** และ **หัวข้อไหนต้องอธิบายข้อจำกัด**:

| หัวข้อในตำราอาจารย์ (บทที่ ๑) | ทำในระบบของเราได้ไหม? | แนวทางปฏิบัติสำหรับคนที่ 3 (ตอนทำแล็บและตอน Demo) |
| :--- | :---: | :--- |
| **๑.1 ขอบเขตทรัพยากร & RBAC `(User, Role, Scope)` Tuple** | ✅ **ทำได้ 100%** | ใช้เป็นกรอบทฤษฎีอธิบายตอนโชว์งาน Admin (System-scope vs Domain-scope vs Project-scope และบทบาท `admin`, `manager`, `member`, `reader`) |
| **๑.2.1 การเพิ่ม Project, กำหนด Quota และสร้าง User** (`Project-A`, `A-user`) | ✅ **ทำได้ 100%** | ทำได้ทั้งบน Horizon (**Identity > Projects / Users**, **Modify Quotas**) และผ่าน CLI (`openstack project/user/role/quota`) |
| **๑.2.2 การสร้าง CirrOS VM โดยไม่ใช้ Volume (`Create New Volume = No`)** | ✅ **ทำได้ 100%** | **ตรงกับภาพ ๑-21 ในตำราอาจารย์เป๊ะ!** เพราะเราตั้ง `enable_cinder: false` จึงต้องเลือก `Create New Volume = No` เพื่อให้เก็บ Boot Image บน Local Storage ของ `compute01` |
| **๑.2.3 การใช้งาน CirrOS ทางคอนโซล (noVNC)** (`cirros` / `gocubsgo`) | ✅ **ทำได้ 100%** | เปิดผ่าน SSH Tunnel พอร์ต `6080` และทดสอบครบทั้ง `ip -4 addr show eth0`, `ping 10.10.10.100` / `10.10.10.1`, `ssh cirros@10.20.20.78` ข้าม Router และ `ping -c 4 8.8.8.8` ออกอินเทอร์เน็ต (`0% packet loss`) |
| **๑.2.4 – ๑.2.5 การสร้าง Security Group (`SSH-ICMP`) และผูกกับ VM** | ✅ **ทำได้ 100%** | สร้างกลุ่มกฎ `SSH-ICMP` (เปิด `ALL ICMP` และ `SSH` พอร์ต 22) แล้วกด **Edit Security Groups** ผูกเข้ากับ VM ตามตำราอาจารย์ได้เลย |
| **๑.2.6 – ๑.2.7 การอัปโหลด Image เข้า Glance และการสร้าง Flavor** | ✅ **ทำได้ 100%** | สาธิตผ่าน Image `cirros-0.6.3` และ Flavor `cs223.tiny` (หรือสร้าง Flavor ใหม่ `m1.small.1` ตามตำราอาจารย์ก็ได้) |
| **๑.2.9 การสร้างคู่คีย์ (Key Pairs)** (`Create Key Pair` / `openstack keypair create`) | ✅ **ทำได้ 100%** | สร้าง Key Pair บน Horizon (**Compute > Key Pairs**) หรือ CLI เพื่อโชว์ให้ครบตามตำราอาจารย์ |
| **๑.2.12 – ๑.2.13 การสร้างระบบเครือข่ายเสมือนภายใน (`Network` + `Subnet` + `Router`)** | ✅ **ทำได้ 100%** | ตรงกับ `cs223-private-net` (`10.10.10.0/24`) และการสร้าง Router เชื่อมเข้ากับซับเน็ต แล้วเปิดหน้า **Network Topology** โชว์แผนผัง |
| **๑.2.15 การจัดสรร Floating IP ให้วีเอ็ม & ออกอินเทอร์เน็ต** | ✅ **ทำได้ 100% (ด้วย Runtime NAT)** | สร้าง `ext-net` (`172.24.4.0/24`, Flat บน `physnet1:br-ex`), ตั้ง Gateway + `iptables MASQUERADE` ออก `ens3` บน `controller01` แล้วจัดสรร Floating IP `172.24.4.122` ผูกกับ `cs223-test-vm` จน `ssh` จากภายนอกและ `ping 8.8.8.8` สำเร็จ *(ค่า Host NAT เป็นชั่วคราวใน RAM)* |
| **๑.2.16 การ Pause, Suspend, Shelve และ Shut off วีเอ็ม** | ✅ **ทำได้ 100%** | สามารถกด **Pause / Unpause** หรือ **Shut Off / Start Instance** บน Horizon โชว์อาจารย์ได้ทันที |
| **๑.2.17 – ๑.2.18 และ ๑.2.21 การรันวีเอ็มบน Volume / Hot Plug Volume (Cinder)** | ⚠️ **ข้าม (Out of Scope)** | เนื่องจากตั้งค่า `enable_cinder: false` จึงไม่มีบริการ Block Storage Volume (ต้องแจ้งในรายงานว่าเป็นขอบเขตที่ปิดไว้) |
| **๑.3 การใช้งานด้วย Command Line Interfaces (CLI)** (`admin-openrc.sh`, สร้าง Project/User/Role/Quota/Network/VM) | ✅ **ทำได้ 100%** | รันบน `controller01` ผ่าน `~/openstack-cli-venv/bin/openstack` ได้ครบทุกคำสั่งตามบทที่ ๑.3 ของอาจารย์ |

---

## 3. ตาราง Test Cases ฉบับสมบูรณ์ (TC-01 ถึง TC-16)

ก่อนรันคำสั่ง CLI บน `controller01` ให้เตรียม Environment ใน Terminal ดังนี้:
```bash
source /etc/kolla/admin-openrc.sh
alias openstack='~/openstack-cli-venv/bin/openstack'
```

| รหัส | หัวข้อการทดสอบ (อ้างอิงตำราอาจารย์) | คำสั่ง CLI (บน `controller01`) | ขั้นตอนบน Horizon (`http://127.0.0.1:8080`) | Expected Result (ผลลัพธ์ที่คาดหวัง) | สิ่งที่ต้องแคปหน้าจอ (Evidence) | สถานะ |
| :--- | :--- | :--- | :--- | :--- | :--- | :---: |
| **TC-01** | **ตรวจสอบสถานะ Containers บนทั้ง 2 Nodes** | บน `controller01`:<br>`sudo docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'`<br>บน `compute01`:<br>`ssh ubuntu@192.168.1.7 "sudo docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'"` | *(ตรวจสอบผ่าน CLI)* | Containers หลักทั้งหมดมีสถานะ `Up` และตัวที่มี Healthcheck แสดง `(healthy)` | [`evidence/02-services/01-controller-containers.png`](../evidence/02-services/01-controller-containers.png) และ [`evidence/02-services/02-compute-containers.png`](../evidence/02-services/02-compute-containers.png) | [x] Pass |
| **TC-02** | **ตรวจสอบ Keystone & รายการ Services (บทที่ ๑.3.2)** | `openstack token issue -f value -c expires`<br>`openstack service list` | ไปที่ **Project** → **API Access** (โชว์ Endpoints และปุ่ม *Download OpenStack RC File* ตามภาพ ๑-142) | ออก Token ได้ และเห็นรายการ Services (`keystone`, `nova`, `neutron`, `glance`, `placement`) ครบถ้วน | [`evidence/02-services/07-cli-services-resources.png`](../evidence/02-services/07-cli-services-resources.png) | [x] Pass |
| **TC-03** | **ตรวจสอบ Nova Compute Services & Hypervisor** | `openstack compute service list`<br>`openstack hypervisor list` | ไปที่ **Admin** → **Compute** → **Hypervisors** | `nova-scheduler`, `nova-conductor` (`controller01`) และ `nova-compute` (`compute01`) เป็น `enabled / up`; เห็น `compute01` มี 4 vCPUs, RAM ~9.9 GB | [`evidence/02-services/03-nova-services.png`](../evidence/02-services/03-nova-services.png) และ [`evidence/02-services/05-horizon-hypervisors.png`](../evidence/02-services/05-horizon-hypervisors.png) | [x] Pass |
| **TC-04** | **ตรวจสอบสถานะ Neutron Network Agents** | `openstack network agent list` | ไปที่ **Admin** → **System** → **System Information** → แท็บ **Network Agents** | พบ Agent ครบ **5 ตัว** (Metadata, DHCP, L3, OVS บน `controller01` และ OVS บน `compute01`) สถานะ `Alive = :-)` และ `State = UP` | [`evidence/02-services/04-neutron-agents.png`](../evidence/02-services/04-neutron-agents.png) และ [`evidence/02-services/06-horizon-network-agents.png`](../evidence/02-services/06-horizon-network-agents.png) | [x] Pass |
| **TC-05** | **การเพิ่ม Image ใน Glance (บทที่ ๑.2.6 & ๑.3.4)** | `openstack image list`<br>`openstack image show cirros-0.6.3` | ไปที่ **Project** → **Compute** → **Images** → กด **Create Image** (Format = `QCOW2` ตามภาพ ๑-41) | Image `cirros-0.6.3` มีสถานะ **`active`**, Disk format = `qcow2`, Visibility = `Private` (โดย `admin` เป็นเจ้าของ) | [`evidence/04-horizon/05-horizon-images.png`](../evidence/04-horizon/05-horizon-images.png) และ [`evidence/02-services/07-cli-services-resources.png`](../evidence/02-services/07-cli-services-resources.png) | [x] Pass |
| **TC-06** | **การเพิ่ม Flavor (บทที่ ๑.2.7 & ๑.3.4)** | `openstack flavor list`<br>`openstack flavor show cs223.tiny` | ไปที่ **Admin** → **Compute** → **Flavors** → กด **Create Flavor** (ตามภาพ ๑-44) | พบ Flavor `cs223.tiny` (1 vCPU, RAM 512 MB, Root Disk 1 GB, `Is Public = True`) | [`evidence/04-horizon/06-horizon-flavors.png`](../evidence/04-horizon/06-horizon-flavors.png) และ [`evidence/02-services/07-cli-services-resources.png`](../evidence/02-services/07-cli-services-resources.png) | [x] Pass |
| **TC-07** | **การสร้างเครือข่ายเสมือนและซับเน็ต (บทที่ ๑.2.12 & ๑.3.6)** | `openstack network show cs223-private-net`<br>`openstack subnet show cs223-private-subnet` | ไปที่ **Project** → **Network** → **Networks** → **Create Network** (ใส่ Subnet `10.10.10.0/24`, Gateway `10.10.10.1`, Enable DHCP, Pool `10.10.10.100–200` ตามภาพ ๑-66 ถึง ๑-68) | Network `cs223-private-net` สถานะ `ACTIVE`, ชนิด `vxlan`, **MTU = `1400`**; Subnet เปิดใช้งาน DHCP | [`evidence/04-horizon/07-horizon-networks-ext.png`](../evidence/04-horizon/07-horizon-networks-ext.png) | [x] Pass |
| **TC-08** | **การสร้างเร้าเตอร์และเชื่อมต่อซับเน็ต (บทที่ ๑.2.13 & ๑.3.7)** | `openstack router create cs223-router`<br>`openstack router add subnet cs223-router cs223-private-subnet`<br>`openstack router show cs223-router` | ไปที่ **Project** → **Network** → **Routers** → **Create Router** (`cs223-router`) → กดชื่อ Router → แท็บ **Interfaces** → **Add Interface** เลือก `cs223-private-subnet` (ตามภาพ ๑-75 ถึง ๑-79) | Router `cs223-router` มีสถานะ `ACTIVE` และเชื่อมต่อกับ `cs223-private-subnet` ที่ขา `10.10.10.1` สำเร็จ | [`evidence/04-horizon/03-network-topology.png`](../evidence/04-horizon/03-network-topology.png), [`evidence/04-horizon/08-horizon-router-interfaces.png`](../evidence/04-horizon/08-horizon-router-interfaces.png) และ [`evidence/05-admin/03-cli-router-secgroup-rbac-quota.png`](../evidence/05-admin/03-cli-router-secgroup-rbac-quota.png) | [x] Pass |
| **TC-09** | **การสร้างกลุ่มกฎรักษาความปลอดภัย `SSH-ICMP` และผูกกับ VM (บทที่ ๑.2.4 – ๑.2.5)** | `openstack security group create SSH-ICMP --description "Allow SSH and ICMP"`<br>`openstack security group rule create --proto icmp SSH-ICMP`<br>`openstack security group rule create --proto tcp --dst-port 22 SSH-ICMP`<br>`openstack server add security group cs223-test-vm SSH-ICMP` | 1. **Project** → **Network** → **Security Groups** → **Create Security Group** (`SSH-ICMP`) → **Manage Rules** → **Add Rule** เลือก `ALL ICMP` และ `SSH` (ภาพ ๑-31 ถึง ๑-36)<br>2. ไปที่ **Instances** → เมนูหลัง VM เลือก **Edit Security Groups** → กด `+` เพิ่ม `SSH-ICMP` (ภาพ ๑-37 ถึง ๑-38) | Security Group `SSH-ICMP` มีกฎ Ingress สำหรับ ICMP และ TCP/22 และถูกผูกเข้ากับ `cs223-test-vm` เรียบร้อย | [`evidence/04-horizon/02-security-group-ssh-icmp.png`](../evidence/04-horizon/02-security-group-ssh-icmp.png) และ [`evidence/05-admin/03-cli-router-secgroup-rbac-quota.png`](../evidence/05-admin/03-cli-router-secgroup-rbac-quota.png) | [x] Pass |
| **TC-10** | **การสร้างคู่คีย์ Key Pair (บทที่ ๑.2.9 & ๑.3.5)** | `openstack keypair create cs223-key > ~/cs223-key.pem`<br>`chmod 600 ~/cs223-key.pem`<br>`openstack keypair list` | ไปที่ **Project** → **Compute** → **Key Pairs** → กด **Create Key Pair** (เลือกชนิด `SSH Key` ตามภาพ ๑-56 ถึง ๑-58) | สร้าง Key Pair สำเร็จ แสดงชื่อและค่า Fingerprint ในรายการ Key Pairs (ห้ามเปิดเผยเนื้อหาไฟล์ `.pem`) | [`evidence/04-horizon/04-key-pairs.png`](../evidence/04-horizon/04-key-pairs.png) | [x] Pass |
| **TC-11** | **การสร้าง CirrOS VM โดยใช้ดิสก์บน Compute Host (บทที่ ๑.2.2 ภาพ ๑-21)** | `openstack server show cs223-test-vm -c name -c status -c addresses -c OS-EXT-SRV-ATTR:host` | ไปที่ **Compute** → **Instances** → **Launch Instance**:<br>- Details: ชื่อ VM<br>- Source: Boot Source = `Image`, **Create New Volume = `No`** (ภาพ ๑-21), เลือก `cirros-0.6.3`<br>- Flavor: `cs223.tiny`<br>- Networks: `cs223-private-net` | Instance `cs223-test-vm` มีสถานะ **`ACTIVE`** รันอยู่บน `compute01` และได้รับ Fixed IP `10.10.10.117` | [`evidence/03-vm-validation/01-instance-active.png`](../evidence/03-vm-validation/01-instance-active.png) และ [`evidence/04-horizon/01-horizon-dashboard.png`](../evidence/04-horizon/01-horizon-dashboard.png) | [x] Pass |
| **TC-12** | **การเข้าใช้งาน VM ทางคอนโซล noVNC และทดสอบเครือข่าย (บทที่ ๑.2.3)** | ขอลิงก์คอนโซล:<br>`openstack console url show --novnc -f value -c url cs223-test-vm \| sed 's#192.168.1.160:6080#127.0.0.1:6080#'`<br>*(ใน CirrOS สั่ง:)*<br>`ip -4 addr show eth0`<br>`ping -c 4 10.10.10.100`<br>`ping -c 4 10.10.10.1` | กดเมนูหลัง VM เลือก **Console** (หรือเปิดผ่าน SSH Tunnel พอร์ต `6080`) ล็อกอินด้วย `cirros` / `gocubsgo` (ตามภาพ ๑-27 ถึง ๑-29) | ล็อกอินเข้า CirrOS ได้; `eth0` แสดง IP `10.10.10.117/24` และ `mtu 1400`; สามารถ Ping ขา DHCP (`10.10.10.100`) และขา Router Gateway (`10.10.10.1`) ได้ `0% packet loss` | [`evidence/03-vm-validation/02-cirros-console.png`](../evidence/03-vm-validation/02-cirros-console.png), [`evidence/03-vm-validation/03-cirros-network.png`](../evidence/03-vm-validation/03-cirros-network.png) และ [`evidence/03-vm-validation/04-cirros-ping-gateway.png`](../evidence/03-vm-validation/04-cirros-ping-gateway.png) | [x] Pass |
| **TC-13** | **การควบคุมสถานะ VM: Pause / Unpause / Shut Off / Start (บทที่ ๑.2.16)** | `openstack server pause cs223-test-vm`<br>`openstack server list`<br>`openstack server unpause cs223-test-vm`<br>`openstack server list` | ที่หน้า **Instances** กดเมนูหลัง VM เลือก **Pause Instance** (สังเกตสถานะเป็น `Paused`) จากนั้นกด **Unpause Instance** ให้กลับมาเป็น `Active` (ตามภาพ ๑-92) | VM เปลี่ยนสถานะเป็น `PAUSED` เมื่อสั่ง Pause และกลับมาเป็น `ACTIVE` ทันทีเมื่อสั่ง Unpause | [`evidence/03-vm-validation/05-instance-paused.png`](../evidence/03-vm-validation/05-instance-paused.png) | [x] Pass |
| **TC-14** | **งาน Admin: การสร้าง Project, User, กำหนด Role และปรับเปลี่ยน Quota (บทที่ ๑.1, ๑.2.1, ๑.2.20 & ๑.3.3)** | `openstack project create --domain default --description "Project A" Project-A`<br>`openstack user create --domain default --project Project-A --password-prompt A-user`<br>`openstack role add --project Project-A --user A-user member`<br>`openstack role assignment list --project Project-A --names`<br>`openstack quota set --instances 5 --cores 4 --ram 4096 --ports 200 Project-A`<br>`openstack quota show Project-A -c Resource -c Limit` | 1. **Identity** → **Projects** → **Create Project** (`Project-A` ตามภาพ ๑-7)<br>2. กดปุ่มเมนูหลัง `Project-A` เลือก **Modify Quotas** → ปรับ Compute (Instances=5, VCPUs=4, RAM=4096) และ Network (Ports=200) (ตามภาพ ๑-10 ถึง ๑-13 และ ๑-128)<br>3. **Identity** → **Users** → **Create User** (`A-user`, Primary Project = `Project-A`, Role = `member` ตามภาพ ๑-15 ถึง ๑-16) | - สร้าง Tuple `(User=A-user, Role=member, Scope=Project-A)` สำเร็จ<br>- ค่า Quota ของ `Project-A` เปลี่ยนแปลงตามที่กำหนด<br>- สามารถทดลองล็อกอิน Horizon ด้วยบัญชี `A-user` เข้าสู่ `Project-A` ได้จริง (เหมือนภาพ ๑-17) | [`evidence/05-admin/01-project-a-edit-quotas.png`](../evidence/05-admin/01-project-a-edit-quotas.png), [`evidence/05-admin/02-a-user-rbac-overview.png`](../evidence/05-admin/02-a-user-rbac-overview.png) และ [`evidence/05-admin/03-cli-router-secgroup-rbac-quota.png`](../evidence/05-admin/03-cli-router-secgroup-rbac-quota.png) | [x] Pass |
| **TC-15** | **การเชื่อมต่อข้าม Virtual Network ผ่าน Virtual Router (East–West Routing)** | `openstack router show cs223-router`<br>`openstack server list`<br>*(ใน `cs223-test-vm` สั่ง:)*<br>`ssh cirros@10.20.20.78`<br>`hostname && ip -4 addr show eth0` | 1. สร้าง Network `cs223-net-2` + Subnet `cs223-subnet-2` (`10.20.20.0/24`, GW `10.20.20.1`)<br>2. ต่อ Interface `cs223-subnet-2` เข้า `cs223-router`<br>3. สร้าง VM `cs223-vm-2` (`cirros-0.6.3`, `cs223.tiny`, `cs223-net-2`, SG `SSH-ICMP`, Key `cs223-key`) | `cs223-vm-2` สถานะ `ACTIVE` (`10.20.20.78/24`, `mtu 1400`) และสามารถ `ssh` จาก `cs223-test-vm` (`10.10.10.117`) ข้าม Router ไปยัง `cs223-vm-2` ได้สำเร็จ | [`evidence/03-vm-validation/06-vm-ssh-inter-subnet.png`](../evidence/03-vm-validation/06-vm-ssh-inter-subnet.png), [`evidence/04-horizon/08-horizon-router-interfaces.png`](../evidence/04-horizon/08-horizon-router-interfaces.png) และ [`evidence/04-horizon/11-horizon-instances-multi.png`](../evidence/04-horizon/11-horizon-instances-multi.png) | [x] Pass |
| **TC-16** | **External Network (`ext-net`), Floating IP, SSH จากภายนอก และ Internet Egress (บทที่ ๑.2.15)** | `openstack network create --external --provider-network-type flat --provider-physical-network physnet1 ext-net`<br>`openstack subnet create --network ext-net --subnet-range 172.24.4.0/24 --gateway 172.24.4.1 --allocation-pool start=172.24.4.100,end=172.24.4.200 --dns-nameserver 8.8.8.8 --no-dhcp ext-subnet`<br>`openstack router set --external-gateway ext-net cs223-router`<br>*(บน `controller01` ตั้ง `br-ex` `172.24.4.1/24` + `ip_forward=1` + `iptables MASQUERADE` ออก `ens3` แล้วทดสอบ `ssh cirros@172.24.4.122` และใน VM สั่ง `ping -c 4 8.8.8.8`)* | 1. **Project → Network → Floating IPs → Allocate IP to Project** (Pool `ext-net`)<br>2. **Associate** `172.24.4.122` เข้ากับ `cs223-test-vm (10.10.10.117)`<br>3. ดูผัง **Network Topology** เชื่อมครบ `ext-net` ↔ `cs223-router` ↔ 2 Tenant Nets | - `cs223-router` มี External Gateway `172.24.4.195` (`enable_snat: true`)<br>- `ssh cirros@172.24.4.122` จาก `controller01` เข้า `cs223-test-vm` สำเร็จ<br>- ใน `cs223-test-vm` สั่ง `ping -c 4 8.8.8.8` ได้ผล `4 received, 0% packet loss` | [`evidence/03-vm-validation/07-controller-br-ex-nat-floating-ip-ssh.jpg`](../evidence/03-vm-validation/07-controller-br-ex-nat-floating-ip-ssh.jpg), [`evidence/03-vm-validation/08-vm-ping-internet.png`](../evidence/03-vm-validation/08-vm-ping-internet.png), [`evidence/03-vm-validation/09-cli-multi-network-floating-ip.png`](../evidence/03-vm-validation/09-cli-multi-network-floating-ip.png), [`evidence/04-horizon/09-horizon-network-topology-ext.png`](../evidence/04-horizon/09-horizon-network-topology-ext.png) และ [`evidence/04-horizon/10-horizon-floating-ips.png`](../evidence/04-horizon/10-horizon-floating-ips.png) | [x] Pass |

---

## 4. สคริปต์รันคำสั่งงานของคนที่ 3 ตามชื่อในตำราอาจารย์ (`Project-A`, `A-user`, `SSH-ICMP`)

เพื่อให้ผลลัพธ์ตรงกับชื่อตัวอย่างในตำราของอาจารย์กษิดิศ (บทที่ ๑.2 และ ๑.3) คุณสามารถก๊อปปี้ชุดคำสั่งนี้ไปรันบน `controller01` ได้เลยครับ:

```bash
(
  source /etc/kolla/admin-openrc.sh
  OSC=~/openstack-cli-venv/bin/openstack

  echo "=== 1. [TC-08] สร้าง Router และเชื่อมต่อเข้ากับ Subnet ==="
  "$OSC" router show cs223-router >/dev/null 2>&1 || "$OSC" router create cs223-router
  "$OSC" router add subnet cs223-router cs223-private-subnet 2>/dev/null || true
  "$OSC" router show cs223-router -c id -c name -c status -c interfaces_info

  echo "=== 2. [TC-09] สร้าง Security Group 'SSH-ICMP' (ตามบทที่ ๑.2.4) และผูกกับ VM ==="
  "$OSC" security group show SSH-ICMP >/dev/null 2>&1 || \
    "$OSC" security group create SSH-ICMP --description "Allow SSH and ICMP (Tutorial 1.2.4)"
  "$OSC" security group rule create --proto icmp SSH-ICMP 2>/dev/null || true
  "$OSC" security group rule create --proto tcp --dst-port 22 SSH-ICMP 2>/dev/null || true
  "$OSC" server add security group cs223-test-vm SSH-ICMP 2>/dev/null || true
  "$OSC" security group rule list SSH-ICMP -c ID -c "IP Protocol" -c "IP Range" -c "Port Range" -c Direction

  echo "=== 3. [TC-10] สร้าง Key Pair (ตามบทที่ ๑.2.9 & ๑.3.5) ==="
  if ! "$OSC" keypair show cs223-key >/dev/null 2>&1; then
    "$OSC" keypair create cs223-key > ~/cs223-key.pem
    chmod 600 ~/cs223-key.pem
  fi
  "$OSC" keypair list

  echo "=== 4. [TC-14] งาน Admin: สร้าง Project-A, A-user, กำหนด Role และปรับ Quota (ตามบทที่ ๑.2.1 & ๑.3.3) ==="
  "$OSC" project show Project-A >/dev/null 2>&1 || \
    "$OSC" project create --domain default --description "Project A for CS223 Admin Test" Project-A
  "$OSC" user show A-user >/dev/null 2>&1 || \
    "$OSC" user create --domain default --project Project-A --password-prompt A-user
  "$OSC" role add --project Project-A --user A-user member
  "$OSC" role assignment list --project Project-A --names

  echo "=== 5. [TC-14] ปรับตั้งค่า Quota ของ Project-A (ตามบทที่ ๑.2.20 & ๑.3.3) ==="
  "$OSC" quota set --instances 5 --cores 4 --ram 4096 --ports 200 Project-A
  "$OSC" quota show Project-A -c Resource -c Limit
)
```
