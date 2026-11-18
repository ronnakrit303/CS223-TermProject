# 09 — ร่างรายงานฉบับสมบูรณ์ (Final Report Draft) และบทพูดวิดีโอสาธิต (Demo Script)

> **CS223 Term Project — OpenStack 2026.1 Multinode Deployment (`grp25`)**  
> **เอกสาร:** โครงสร้างและเนื้อหาร่างรายงานฉบับสมบูรณ์ (ปรับปรุงให้สอดคล้องกับ [ตำราอาจารย์กษิดิศ บทที่ ๑](https://kasidit.github.io/OpenStack-Tutorial-0.01/)) สำหรับจัดหน้าด้วยฟอนต์ **TH Sarabun** และส่งเป็นไฟล์ **PDF** พร้อมแนวทางนำเสนอความคืบหน้า (18 พ.ย.) และบทพูด Demo Video (8 ธ.ค.)

[← QA Test Cases & Admin](08-qa-test-cases-and-admin.md) · [README](../README.md)

---

## ส่วนที่ 1: สรุปการเตรียมตัวสำหรับ Present ในห้องเรียน (18 พ.ย. 2026 เวลา 15:00–16:30 น.)

ตามประกาศของอาจารย์ การนำเสนอวันที่ **18 พฤศจิกายน 2026** เป็นการเดินตรวจแต่ละกลุ่มหน้าห้อง (ไม่บังคับสไลด์ PowerPoint แต่ควรเปิดหน้าจอไว้ให้พร้อม) โดยปัจจุบันกลุ่ม `grp25` **ติดตั้งและรัน Test VM สำเร็จไปไกลกว่าเกณฑ์ขั้นต่ำของวันตรวจความคืบหน้าแล้ว** สิ่งที่ต้องเปิดรอไว้บนหน้าจอและแบ่งกันเล่าใน 5 นาที มีดังนี้:

1. **คนที่ 1 (เล่าข้อ 1 & 2 — หัวข้อ, ประโยชน์ และ Architecture):**
   - เปิดแผนภาพ Architecture ใน [`docs/02-architecture.md`](02-architecture.md)
   - อธิบายการวางโครงสร้าง **Outer OpenStack (ของอาจารย์)** ซ้อนด้วย **Inner OpenStack 2 Nodes ของกลุ่ม** (`controller01` `192.168.1.160` และ `compute01` `192.168.1.7`)
   - ชี้จุดแก้ปัญหา Infrastructure: การแยกดิสก์ 40 GB ไปไว้ที่ `/var/lib/docker`, การเช็ก `/dev/kvm`, การใช้ `dummy0` เพื่อรักษา SSH บน `ens3` และการตั้งค่า MTU 1450 -> VXLAN MTU 1400
2. **คนที่ 2 (เล่าข้อ 3 & 4 — การ Deploy และอุปสรรคที่แก้สำเร็จ):**
   - เปิดไฟล์ [`config/multinode.example`](../config/multinode.example) และ [`config/globals.example.yml`](../config/globals.example.yml)
   - อธิบายการตั้งค่า Single Controller Non-HA (`kolla_internal_vip_address: "192.168.1.160"`) เพื่อไม่ให้ติด Neutron Port Security บนระบบชั้นนอก
   - เล่าอุปสรรคจริงที่เจอและแก้ได้แล้ว: ตอน Deploy รอบแรก MariaDB พัง (`EXIT STATUS: 2`) เพราะพอร์ต `3306` ชนกับ `ProxySQL` และต้องสั่งหยุดผ่าน `systemd` (`systemctl stop kolla-proxysql-container.service`) ก่อน Deploy รอบใหม่จนผ่าน (`failed=0`)
3. **คนที่ 3 (เล่าข้อ 3 & 5 — สาธิตการใช้งานจริง, งาน Admin และการแบ่งงาน):**
   - เปิดหน้าเว็บ **Horizon Dashboard** (`http://127.0.0.1:8080` ผ่าน SSH Tunnel) และหน้าต่าง **noVNC Console** ของ `cs223-test-vm`
   - โชว์ตามลำดับตำราบทที่ ๑ ของอาจารย์:
     1) อธิบายการจัดการสิทธิ์ด้วย RBAC **`(User, Role, Scope)` Tuple** และการสร้าง `Project-A`, ผู้ใช้ `A-user` (Role `member` ใน `Project-scope`) พร้อมการปรับ **Quota**
     2) โชว์การล็อกอินด้วย `A-user` (ที่จะไม่เห็นแท็บ `Admin` บนซ้ายมือ ต่างจากบัญชี `admin` ที่มีทั้ง `System-scope` และ `Project-scope`)
     3) โชว์การสร้าง Security Group `SSH-ICMP`, เครือข่ายเสมือน `cs223-private-net` + `cs223-net-2`, เร้าเตอร์ `cs223-router`, External Network `ext-net`, Floating IP `172.24.4.122` และสร้าง VM (`cs223-test-vm`, `cs223-vm-2`) โดยเลือก **`Create New Volume = No`** (ใช้ดิสก์ของ Compute Host `compute01`)
     4) โชว์หน้าจอ Console ของ CirrOS ที่ได้รับ IP `10.10.10.117/24` (`mtu 1400`), `ssh` ข้าม Subnet ไป `cs223-vm-2` (`10.20.20.78`), `ssh cirros@172.24.4.122` และ `ping -c 4 8.8.8.8` (`0% packet loss`) สำเร็จ!

---

## ส่วนที่ 2: เนื้อหาร่างรายงานฉบับสมบูรณ์ (พร้อมคัดลอกลง Word / Google Docs ตั้งฟอนต์ TH Sarabun)

> [!IMPORTANT]
> **ข้อกำหนดการส่งรายงาน (Due: 8 ธ.ค. 2569):**
> - ใช้ตัวอักษร **TH Sarabun** ทั้งฉบับและแปลงเป็นไฟล์ **`.pdf`**
> - ระบุ **Assignment**, **Students (ชื่อและรหัสนักศึกษาครบทั้ง 3 คน)** และ **ลิงก์ Demo Video** ที่หน้าแรกอย่างชัดเจน
> - **ห้ามใส่รหัสผ่านจริง, Private Key หรือ Token ใดๆ ลงในรายงาน**

---

### Assignment: หัวข้อที่ 4 — ติดตั้ง และ Admin ระบบ OpenStack 2 [Implementation]
**Students:**
1. [ชื่อ-นามสกุล สมาชิกคนที่ 1] รหัสนักศึกษา [XXXXXXXXXX]
2. [ชื่อ-นามสกุล สมาชิกคนที่ 2] รหัสนักศึกษา [XXXXXXXXXX]
3. [ชื่อ-นามสกุล สมาชิกคนที่ 3] รหัสนักศึกษา [XXXXXXXXXX]

**กลุ่มที่:** 25 (`grp25`)  
**Demo Video Link:** [วางลิงก์ YouTube / Facebook / Google Drive ที่ตั้งค่าสาธารณะแล้วที่นี่]  
**GitHub Repository:** https://github.com/ronnakrit303/CS223-TermProject

---

### 1. แนะนำหัวข้อ วัตถุประสงค์ และประโยชน์ของสิ่งที่ทำ

#### 1.1 ที่มาและความสำคัญของโครงงาน
เทคโนโลยีการจำลองเสมือน (Virtualization) เป็นรากฐานสำคัญของระบบ Cloud Computing สมัยใหม่ อย่างไรก็ตาม การรัน Virtual Machine (VM) บน Hypervisor เพียงเครื่องเดียวยังไม่เพียงพอต่อการบริหารจัดการโครงสร้างพื้นฐานระดับองค์กร ซึ่งจำเป็นต้องมีระบบจัดการตัวตนและสิทธิ์การเข้าถึงแบบ Role-Based Access Control (RBAC), ระบบจัดสรรทรัพยากรประมวลผลและโควตา (Compute, Placement & Quota), ระบบเครือข่ายเสมือน (Software-Defined Networking) และระบบจัดเก็บอิมเมจ (Image Repository) ที่ทำงานประสานกัน

โครงงานนี้จึงมุ่งศึกษาและลงมือติดตั้งระบบ Private Cloud แบบ Infrastructure-as-a-Service (IaaS) ด้วยซอฟต์แวร์ **OpenStack (รุ่น 2026.1)** ในรูปแบบ **Multi-node จำนวน 2 เครื่อง** (แยกบทบาทระหว่าง Controller Node และ Compute Node) โดยใช้เครื่องมือ **Kolla Ansible** ในการ Deploy บริการทั้งหมดของ OpenStack ในรูปแบบ Docker Containers บนระบบปฏิบัติการ **Ubuntu Server 24.04.3 LTS** พร้อมทั้งทดสอบการใช้งานและการบริหารจัดการระบบผ่านทั้ง **Web Dashboard (Horizon)** และ **Command Line Interfaces (OpenStack CLI)**

#### 1.2 วัตถุประสงค์ของโครงงาน
1. เพื่อศึกษาสถาปัตยกรรมและการทำงานร่วมกันของบริการหลักใน OpenStack แบบแยก Node (`controller01` และ `compute01`)
2. เพื่อประยุกต์ใช้ Ansible และ Kolla Ansible ในการเตรียมสภาพแวดล้อม ตรวจสอบความพร้อม (`prechecks`) และติดตั้งบริการ OpenStack แบบอัตโนมัติ
3. เพื่อศึกษาและทดลองบริหารจัดการสิทธิ์การเข้าถึงทรัพยากรตามแนวคิด `(User, Role, Scope)` Tuple และการกำหนดโควตาทรัพยากร (Quota) ของแต่ละ Project
4. เพื่อทดสอบการใช้งานจริงตั้งแต่การอัปโหลด Image เข้าสู่ Glance, การสร้าง Flavor, การสร้างเครือข่ายเสมือนภายในและเร้าเตอร์เสมือน, การกำหนดกฎไฟร์วอลล์ใน Security Group และการสร้าง VM ให้ทำงานบน Compute Node พร้อมเข้าถึงผ่านคอนโซล (noVNC)

#### 1.3 ประโยชน์ที่ได้รับจากการทำโครงงาน
1. เข้าใจกลไกเบื้องหลังการสร้าง VM หนึ่งเครื่องว่าต้องผ่านการประสานงานระหว่าง Keystone, Nova, Placement, Glance, Neutron และ Libvirt/QEMU-KVM อย่างไร
2. เข้าใจความแตกต่างของขอบเขตการเข้าถึงทรัพยากร 3 ระดับ (`System-scope`, `Domain-scope`, และ `Project-scope`) และการแยกส่วนผู้ดูแลระบบ (`admin`) ออกจากผู้ใช้ทรัพยากรภายในโปรเจกต์ (`member`)
3. เรียนรู้การออกแบบเครือข่าย Overlay (VXLAN), การแก้ปัญหาข้อจำกัดด้าน Port Security และค่า MTU ในสภาพแวดล้อมที่มีการรันระบบคลาวด์ซ้อนกัน (Nested OpenStack)

---

### 2. สถาปัตยกรรมและโครงสร้างของระบบ (System Architecture)

#### 2.1 สถาปัตยกรรมแบบหลายชั้น (Nested OpenStack Architecture)
ระบบ OpenStack ของกลุ่มได้รับการติดตั้งอยู่ภายใน Virtual Machines จำนวน 2 เครื่องที่สร้างขึ้นบนระบบ OpenStack ของรายวิชาอีกชั้นหนึ่ง (Nested Virtualization) จึงต้องแยกความหมายของระบบคลาวด์ออกเป็น 3 ชั้นอย่างชัดเจน ได้แก่:
* **ชั้นที่ 0 — Outer Cloud (OpenStack ของรายวิชา):** ทำหน้าที่จัดสรร Host VMs จำนวน 2 เครื่อง (`controller01` และ `compute01`) เชื่อมต่อกันผ่านเครือข่าย `localnet1` (`192.168.1.0/24`, MTU `1450`)
* **ชั้นที่ 1 — Inner Cloud (OpenStack 2026.1 ของกลุ่ม `grp25`):** ติดตั้งด้วย Kolla Ansible (`22.2.1.dev36`) แยกบทบาท Control/Network Plane ไว้ที่ `controller01` และแยก Compute/Hypervisor Plane ไปไว้ที่ `compute01`
* **ชั้นที่ 2 — Guest Workload:** เครื่องเสมือนทดสอบที่สร้างขึ้นภายใน Inner Cloud และประมวลผลจริงบน Hypervisor ของ `compute01` ได้แก่ `cs223-test-vm` (`10.10.10.117`, Floating IP `172.24.4.122`) และ `cs223-vm-2` (`10.20.20.78`) รันเกสต์โอเอส CirrOS 0.6.3

*(แทรกแผนภาพสถาปัตยกรรมจาก `docs/02-architecture.md`)*

#### 2.2 รายละเอียดของ Nodes และการแบ่งหน้าที่

| คุณสมบัติ | `controller01` (Controller & Network Node) | `compute01` (Compute Node) |
| :--- | :--- | :--- |
| **กลุ่มใน Ansible Inventory** | `[control]`, `[network]`, `[monitoring]`, `[storage]`, `[deployment]` | `[compute]` |
| **ระบบปฏิบัติการ** | Ubuntu Server 24.04.3 LTS | Ubuntu Server 24.04.3 LTS |
| **Management / Tunnel IP** | `192.168.1.160` (`ens3`, MTU 1450) | `192.168.1.7` (`ens3`, MTU 1450) |
| **สเปกทรัพยากร (vCPU / RAM)** | 4 vCPU / RAM ~9.7 GiB | 4 vCPU / RAM ~9.7 GiB (9,945 MB) |
| **การจัดสรรพื้นที่ดิสก์** | Root Disk 30 GB + Volume แยก 40 GB (`ext4` Mount ที่ `/var/lib/docker`) | Root Disk 30 GB + Volume แยก 40 GB (`ext4` Mount ที่ `/var/lib/docker`) |
| **บริการ OpenStack ที่รัน** | Keystone, Nova API/Scheduler/Conductor/noVNC, Glance, Placement, Neutron Server/DHCP/L3/Metadata/OVS, Horizon, MariaDB, RabbitMQ, Memcached | `nova-compute`, Libvirt / QEMU-KVM (`/dev/kvm`), Neutron Open vSwitch Agent |

#### 2.3 การตัดสินใจเชิงสถาปัตยกรรมและการตั้งค่า Configuration สำคัญ
เพื่อให้ระบบ OpenStack ชั้นในทำงานร่วมกับข้อจำกัดของ OpenStack ชั้นนอกได้โดยไม่เกิดปัญหา กลุ่มได้ออกแบบและกำหนดค่าใน `/etc/kolla/globals.yml` ดังนี้:
1. **การแยกพื้นที่เก็บข้อมูล Docker (`/var/lib/docker`):** เนื่องจาก Root Disk ของ Flavor มาตรฐานมีขนาดจำกัด จึงสร้าง Volume ขนาด 40 GB แยกต่างหากและนำไป Mount ที่ `/var/lib/docker` บนทั้งสองเครื่อง เพื่อรองรับขนาดของ Kolla Container Images
2. **การกำหนด Internal VIP แบบ Single-Controller Non-HA:** บนเครือข่ายของ Outer OpenStack มีกลไก Port Security (Anti-spoofing) ที่อาจบล็อก Virtual IP (VIP) แปลกปลอมจาก Keepalived กลุ่มจึงกำหนด `kolla_internal_vip_address: "192.168.1.160"` ให้ใช้ IP จริงของ `controller01` โดยตรง และตั้งค่าปิด `enable_haproxy: false`, `enable_keepalived: false`, `enable_loadbalancer: false` และ `enable_proxysql: false`
3. **การใช้อินเทอร์เฟซจำลอง `dummy0` สำหรับ `br-ex` ร่วมกับ Runtime NAT:** กำหนด `neutron_external_interface: "dummy0"` บน `controller01` เพื่อให้ Open vSwitch สร้างบริดจ์ `br-ex` ได้โดยไม่ดึงพอร์ต `ens3` (ที่ใช้รีโมต SSH และจัดการระบบ) เข้าไปอยู่ในบริดจ์ และเมื่อสร้าง External Network (`ext-net` `172.24.4.0/24` ชนิด Flat บน `physnet1:br-ex`) ได้กำหนด IP `172.24.4.1/24` ให้ Interface ภายใน `br-ex` พร้อมเปิด `ip_forward=1` และ `iptables MASQUERADE` ออกทาง `ens3` แบบ Runtime ทำให้ Guest VM ใช้ Floating IP และออกอินเทอร์เน็ตได้จริงโดยไม่กระทบการเชื่อม SSH ของทีม
4. **การปรับค่า MTU สำหรับเครือข่าย VXLAN (`1450 -> 1400`):** เนื่องจากพอร์ต `ens3` บน Outer Cloud มีค่า MTU เท่ากับ `1450` bytes กลุ่มจึงสร้างไฟล์ Override `/etc/kolla/config/neutron/neutron.conf` (`global_physnet_mtu = 1450`) และ `/etc/kolla/config/neutron/ml2_conf.ini` (`path_mtu = 1450`) เพื่อให้ Neutron หักลบ VXLAN Header (50 bytes) และกำหนดค่า MTU ของเครือข่ายเสมือนภายในเป็น **`1400` bytes** อัตโนมัติ
5. **การเลือกใช้ Local Storage ของ Compute Host แทน Cinder Volume:** ตั้งค่า `enable_cinder: false` และ `enable_heat: false` ตามขอบเขตพื้นฐาน โดยเมื่อสร้าง VM จะกำหนด `Create New Volume = No` เพื่อให้ Nova เก็บ Boot Image ลงบนดิสก์ของ `compute01` โดยตรง

---

### 3. ผลลัพธ์ของงานและการทดสอบระบบ (Implementation, Usage & Administration Results)

#### 3.1 ผลการติดตั้งระบบด้วย Kolla Ansible
บนเครื่อง `controller01` ได้สร้าง Python Virtual Environment แยกกันระหว่าง `~/kolla-venv` (สำหรับรัน Ansible Core `2.19.15` และ Kolla Ansible `22.2.1.dev36`) และ `~/openstack-cli-venv` (สำหรับรัน `python-openstackclient 9.0.1`) จากนั้นรันคำสั่งติดตั้งตามลำดับ ได้แก่ `bootstrap-servers`, `prechecks`, `deploy` และ `post-deploy`
* ผลการรัน `prechecks` และ `deploy` รอบสมบูรณ์: ไม่มีโฮสต์ใดล้มเหลว (`compute01: ok=93, failed=0`, `controller01: ok=283, failed=0`) และจบด้วย `DEPLOY EXIT STATUS: 0`
* ผลการรัน `post-deploy`: ระบบสร้างไฟล์สคริปต์พิสูจน์ตัวตน `/etc/kolla/admin-openrc.sh` และ `/etc/kolla/clouds.yaml` สำหรับผู้ดูแลระบบเรียบร้อย

*(แทรกรูปผลลัพธ์ `PLAY RECAP` และภาพ `docker ps` บนทั้ง 2 เครื่อง)*

#### 3.2 ผลการตรวจสอบสถานะ Services, Compute Node และ Network Agents
เมื่อโหลดสคริปต์พิสูจน์ตัวตนของผู้ดูแลระบบ (`source /etc/kolla/admin-openrc.sh`) และตรวจสอบผ่าน OpenStack CLI พบผลลัพธ์ดังนี้:
1. **รายการ Services (`openstack service list`):** บริการหลักทั้ง 5 ส่วน ได้แก่ `keystone` (identity), `nova` (compute), `placement` (placement), `glance` (image) และ `neutron` (network) ลงทะเบียนพร้อมใช้งานครบถ้วน
2. **สถานะ Compute Services (`openstack compute service list`):** บริการ `nova-scheduler` และ `nova-conductor` บน `controller01` รวมถึง `nova-compute` บน `compute01` มีสถานะเป็น `enabled` และ `State = up` ทั้งหมด และคำสั่ง `openstack hypervisor list` แสดงโฮสต์ `compute01` มีสถานะ `up` (4 vCPUs, RAM 9,945 MB, Disk 39 GB)
3. **สถานะ Network Agents (`openstack network agent list`):** พบตัวแทนจัดการเครือข่ายครบทั้ง 5 ตัว ได้แก่ Metadata Agent, Open vSwitch Agent, DHCP Agent, L3 Agent บน `controller01` และ Open vSwitch Agent บน `compute01` มีสถานะ `Alive = :-)` และ `State = UP`

*(แทรกรูป `evidence/02-services/03-nova-services.png` และ `evidence/02-services/04-neutron-agents.png`)*

#### 3.3 การบริหารจัดการสิทธิ์ตามแนวคิด RBAC, การสร้าง Project, User และการกำหนด Quota
ตามหลักการ Role-Based Access Control (RBAC) ของระบบคีย์สโตน (Keystone) สิทธิ์การใช้งานทรัพยากรเกิดจากความสัมพันธ์ของ **`(User, Role, Scope)` Tuple** โดยเมื่อติดตั้งเสร็จ Kolla Ansible ได้ทำกระบวนการ `keystone-manage bootstrap` สร้างบัญชี `admin` ที่มีทั้งบุคลิกภาพระดับทั้งระบบ `(User=admin, Role=admin, Scope=system)` และระดับโปรเจกต์ `(User=admin, Role=admin, Scope=project)` ทำให้เมื่อล็อกอินเข้าสู่ Horizon Dashboard (`http://127.0.0.1:8080/` ผ่าน SSH Tunnel) ผู้ใช้ `admin` จะมองเห็นแท็บเมนูครบทั้ง 3 หมวด คือ **Project**, **Admin** และ **Identity**

กลุ่มได้ทดสอบงานผู้ดูแลระบบตามขั้นตอนในบทที่ ๑.2.1, ๑.2.20 และ ๑.3.3 ดังนี้:
1. **การสร้าง Project และกำหนด Quota:** สร้างโปรเจกต์ใหม่ชื่อ `Project-A` (และ `cs223-qa-project`) ภายใต้ `default` domain จากนั้นใช้เมนู **Modify Quotas** และคำสั่ง `openstack quota set` เพื่อกำหนดโควตาทรัพยากรประมวลผลและเครือข่าย ได้แก่ จำนวนวีเอ็มสูงสุด (`Instances = 5`), จำนวนซีพียูคอร์รวม (`VCPUs = 4`), ขนาดหน่วยความจำรวม (`RAM = 4,096 MB`) และจำนวนพอร์ตเครือข่าย (`Ports = 200`)
2. **การสร้าง User และกำหนด Role ในระดับ Project Scope:** สร้างบัญชีผู้ใช้ใหม่ชื่อ `A-user` (และ `cs223_tester`) และกำหนดความสัมพันธ์ให้มีบทบาทเป็นสมาชิกของโปรเจกต์ `(User=A-user, Role=member, Scope=Project-A)` ด้วยคำสั่ง `openstack role add --project Project-A --user A-user member`
3. **การพิสูจน์สิทธิ์ตามบุคลิกภาพ (Persona Verification):** เมื่อทดลองล็อกอินเข้าสู่ Horizon Dashboard ด้วยบัญชี `A-user` พบว่าผู้ใช้จะเข้าสู่ `Project-A` โดยมีสิทธิ์สร้างและใช้ทรัพยากรภายในโควตาของ `Project-A` ได้ แต่ **จะไม่เห็นแท็บเมนู Admin** ซึ่งพิสูจน์การทำงานของกลไก RBAC ได้อย่างถูกต้อง

*(แทรกรูปหน้าจอ Horizon: ภาพรวม Limit Summary `evidence/04-horizon/01-horizon-dashboard.png`, หน้าสร้าง Project/User, หน้า Modify Quotas และผลรัน `openstack role assignment list` / `openstack quota show`)*

#### 3.4 การเตรียม Image, Flavor, เครือข่ายเสมือน, เร้าเตอร์ และ Security Group
กลุ่มได้ทดสอบการเตรียมทรัพยากรพื้นฐานทั้งผ่าน Horizon Dashboard และ OpenStack CLI ดังนี้:
1. **การเพิ่ม Image ใน Glance (บทที่ ๑.2.6 & ๑.3.4):** อัปโหลดไฟล์อิมเมจของเกสต์โอเอส CirrOS 0.6.3 (`qcow2`) เข้าสู่ Glance ในชื่อ `cirros-0.6.3` กำหนด Visibility เป็น `Public` และตรวจสอบว่ามีสถานะเป็น `active`
2. **การเพิ่ม Flavor (บทที่ ๑.2.7 & ๑.3.4):** สร้างข้อกำหนดสเปกของวีเอ็มชื่อ `cs223.tiny` กำหนดค่า `VCPUs = 1`, `RAM = 512 MB` และ `Root Disk = 1 GB`
3. **การสร้างเครือข่ายเสมือนภายใน, เครือข่ายภายนอก และเร้าเตอร์เสมือน (บทที่ ๑.2.12 – ๑.2.13, ๑.2.15 & ๑.3.6 – ๑.3.7):**
   - สร้างเครือข่ายเสมือนภายในวงที่ 1 ชื่อ `cs223-private-net` (ชนิด `vxlan`, MTU `1400`) พร้อมซับเน็ต `cs223-private-subnet` (`10.10.10.0/24`, Gateway `10.10.10.1`, DHCP Pool `10.10.10.100–10.10.10.200`)
   - สร้างเครือข่ายเสมือนภายในวงที่ 2 ชื่อ `cs223-net-2` (ชนิด `vxlan`, MTU `1400`) พร้อมซับเน็ต `cs223-subnet-2` (`10.20.20.0/24`, Gateway `10.20.20.1`) เพื่อทดสอบการเชื่อมต่อข้ามเครือข่าย
   - สร้างเครือข่ายภายนอกชื่อ `ext-net` (ชนิด `flat`, Physical Network `physnet1` เชื่อม `br-ex`) พร้อมซับเน็ต `ext-subnet` (`172.24.4.0/24`, Pool `172.24.4.100–172.24.4.200`, Gateway `172.24.4.1`)
   - สร้างเร้าเตอร์เสมือนชื่อ `cs223-router` เชื่อมต่อครบทั้ง 3 ขา (`10.10.10.1`, `10.20.20.1` และ External Gateway `172.24.4.195` แบบ `enable_snat: true`) แสดงผังครบถ้วนในหน้า **Network Topology**
4. **การสร้างกลุ่มกฎรักษาความปลอดภัย `SSH-ICMP` และคู่คีย์ (บทที่ ๑.2.4 & ๑.2.9):**
   - เนื่องจาก `default` security group อนุญาตเฉพาะทราฟฟิกขาออกจากวีเอ็ม จึงได้สร้างกลุ่มกฎรักษาความปลอดภัยใหม่ชื่อ `SSH-ICMP` เพิ่มกฎอนุญาตทราฟฟิกขาเข้าแบบ `ALL ICMP` (สำหรับคำสั่ง `ping`) และ `SSH` (TCP พอร์ต 22)
   - ทดสอบการสร้างคู่คีย์ `cs223-key` ผ่านเมนู **Compute > Key Pairs** และคำสั่ง `openstack keypair create` แล้วนำไปใช้สร้าง VM เครื่องที่ 2 (`cs223-vm-2`)

*(แทรกรูป `evidence/04-horizon/05-horizon-images.png`, `06-horizon-flavors.png`, `07-horizon-networks-ext.png`, `08-horizon-router-interfaces.png`, `09-horizon-network-topology-ext.png`, `02-security-group-ssh-icmp.png` และ `04-key-pairs.png`)*

#### 3.5 การสร้างวีเอ็ม CirrOS, การใช้งานทางคอนโซล, Virtual Routing และ Floating IP
1. **การสร้างวีเอ็มโดยใช้ดิสก์บนเครื่อง Compute Host (บทที่ ๑.2.2 ภาพ ๑-21):**
   - สั่งสร้างวีเอ็ม `cs223-test-vm` (เครือข่าย `cs223-private-net`) และ `cs223-vm-2` (เครือข่าย `cs223-net-2`, Key Pair `cs223-key`) โดยเลือก Boot Source เป็น `Image` (`cirros-0.6.3`), กำหนด **`Create New Volume = No`** (ให้ Nova รันบน Local Storage ของเครื่อง `compute01`), เลือก Flavor `cs223.tiny` และผูกกลุ่มกฎไฟร์วอลล์ `SSH-ICMP`
   - ผลลัพธ์พบว่าทั้ง `cs223-test-vm` (`10.10.10.117`) และ `cs223-vm-2` (`10.20.20.78`) มีสถานะ **`ACTIVE`** รันอยู่บนโฮสต์ **`compute01`**
2. **การเข้าใช้งานผ่านคอนโซล noVNC และทดสอบเครือข่ายภายใน (บทที่ ๑.2.3):**
   - เปิดหน้าต่างคอนโซลของ `cs223-test-vm` ผ่าน SSH Tunnel พอร์ต `6080` และล็อกอินด้วย `cirros` / `gocubsgo`
   - รัน `ip -4 addr show eth0` พบ `UP, LOWER_UP`, ค่า **`mtu 1400`** และได้รับไอพี **`10.10.10.117/24`** จาก DHCP Agent (`10.10.10.100`)
   - ทดสอบ `ping -c 4 10.10.10.100` (DHCP Server) และ `ping -c 4 10.10.10.1` (Router Gateway) สำเร็จ (`0% packet loss`)
3. **การทดสอบ Virtual Routing ข้ามวงแลน (Inter-Subnet SSH):**
   - จากภายใน `cs223-test-vm` (`10.10.10.117`) สั่ง `ssh cirros@10.20.20.78` ข้ามเร้าเตอร์ `cs223-router` ไปยัง `cs223-vm-2` ได้สำเร็จ โดย `hostname` แสดง `cs223-vm-2` และ `eth0` มี IP `10.20.20.78/24`, `mtu 1400`
4. **การผูก Floating IP (`172.24.4.122`), SSH จากภายนอก และ Internet Egress (บทที่ ๑.2.15):**
   - จัดสรรและผูก Floating IP `172.24.4.122` จาก `ext-net` เข้ากับ `cs223-test-vm` (`10.10.10.117`) พร้อมตั้งค่า `172.24.4.1/24` บน `br-ex` และ `iptables MASQUERADE` ออกทาง `ens3` บน `controller01`
   - ทดสอบ `ssh cirros@172.24.4.122` จากเครื่อง `controller01` สามารถเข้าสู่ `cs223-test-vm` ได้โดยตรง และจากภายใน `cs223-test-vm` สั่ง `ping -c 4 8.8.8.8` ออกอินเทอร์เน็ตได้สำเร็จ (`4 packets transmitted, 4 received, 0% packet loss`)
5. **การทดสอบหยุดและเริ่มการประมวลผลของวีเอ็ม (บทที่ ๑.2.16):**
   - ทดสอบคำสั่ง **Pause Instance** (สถานะเป็น `Paused`) และ **Unpause Instance** ให้กลับมาเป็น `Active` ได้อย่างถูกต้อง

*(แทรกรูป `evidence/03-vm-validation/01-instance-active.png` ถึง `09-cli-multi-network-floating-ip.png` และ `evidence/04-horizon/10-horizon-floating-ips.png`, `11-horizon-instances-multi.png`)*

---

### 4. อุปสรรค ปัญหาที่พบ และสิ่งที่ไม่ได้อยู่ในขอบเขต (Challenges & Limitations)

#### 4.1 อุปสรรคและปัญหาที่พบระหว่างการติดตั้งพร้อมวิธีแก้ไข
1. **ปัญหา MariaDB ไม่ผ่านการตรวจสอบ Port Liveness ที่พอร์ต `3306` (`DEPLOY EXIT STATUS: 2`):**
   - **อาการ:** ในการรัน `kolla-ansible deploy` รอบแรก Playbook หยุดทำงานที่ขั้นตอน `Wait for first MariaDB service port liveness` บน `192.168.1.160:3306`
   - **สาเหตุ:** ในการตั้งค่า Single Controller ที่ใช้ IP จริงของตัวเครื่องเป็น Internal VIP บริการ `proxysql` และ `haproxy` ที่เคยถูกสร้างไว้ได้แย่งจับพอร์ต `3306` ชนกับ MariaDB และแม้จะตั้งค่า `enable_proxysql: false` ใน `globals.yml` แล้ว แต่การสั่งหยุด Docker Container เพียงอย่างเดียวไม่เพียงพอ เพราะมี `systemd` unit (`kolla-proxysql-container.service`) คอยสั่งเริ่ม Container ใหม่อัตโนมัติ
   - **วิธีแก้ไข:** สั่งหยุดบริการผ่าน `systemd` ด้วยคำสั่ง `sudo systemctl stop kolla-proxysql-container.service kolla-haproxy-container.service` ตามด้วย `sudo systemctl daemon-reload` และตรวจสอบด้วย `sudo ss -ltnp '( sport = :3306 )'` จนมั่นใจว่าพอร์ตว่างก่อนรัน `prechecks` และ `deploy` ซ้ำจนผ่าน (`EXIT STATUS: 0`)
2. **ปัญหาการเข้าถึง Horizon Dashboard และ noVNC Console บน Private IP:**
   - **อาการ:** เครื่องคอมพิวเตอร์ของนักศึกษาไม่สามารถเปิด `http://192.168.1.160` หรือลิงก์คอนโซลพอร์ต `6080` ได้โดยตรง เนื่องจากเป็น Private IP ภายในวงแลนของ Outer OpenStack
   - **วิธีแก้ไข:** ใช้ SSH Local Port Forwarding จากเครื่องนักศึกษาผ่าน Floating IP ของ `controller01` โดยผูกพอร์ต `127.0.0.1:8080 -> 192.168.1.160:80` สำหรับ Horizon และ `127.0.0.1:6080 -> 192.168.1.160:6080` สำหรับ noVNC
3. **ข้อจำกัดด้านค่า MTU ของเครือข่ายซ้อนทับ (Nested Network MTU 1450):**
   - **อาการ:** เครือข่าย `localnet1` ของ Outer OpenStack มีค่า MTU 1450 bytes ซึ่งต่ำกว่าค่ามาตรฐาน 1500 bytes
   - **วิธีแก้ไข:** ตั้งค่า Override `global_physnet_mtu = 1450` และ `path_mtu = 1450` เพื่อให้เครือข่าย VXLAN ของ Inner OpenStack ใช้ค่า MTU ที่ `1400` bytes ป้องกันปัญหาแพ็กเก็ตสูญหายจากการห่อหุ้มข้อมูลซ้อนกัน
4. **ปัญหา `Destination Host Unreachable` เมื่อทดสอบ `ping 8.8.8.8` หลังสร้าง External Network (`ext-net`):**
   - **อาการ:** หลังสร้าง `ext-net` (`172.24.4.0/24`) และต่อเข้า `cs223-router` แล้ว เมื่อสั่ง `ping -c 4 8.8.8.8` จาก `cs223-test-vm` พบข้อความตอบกลับ `From 172.24.4.122 icmp_seq=1 Destination Host Unreachable`
   - **สาเหตุ:** OVS Bridge `br-ex` บน `controller01` ผูกอยู่กับ `dummy0` จึงยังอยู่ในสถานะ `DOWN` และไม่มี IP Gateway (`172.24.4.1/24`) รวมถึงยังไม่ได้เปิด IP Forwarding และ NAT (`MASQUERADE`) ออกทาง `ens3`
   - **วิธีแก้ไข:** กำหนด IP `172.24.4.1/24` ให้ `br-ex`, สั่ง `ip link set br-ex up`, เปิด `net.ipv4.ip_forward=1`, เพิ่มกฎ `iptables -t nat -A POSTROUTING -s 172.24.4.0/24 -o ens3 -j MASQUERADE` และแทรกกฎ `FORWARD` ที่ลำดับ 1 (`-I FORWARD 1`) ระหว่าง `br-ex` ↔ `ens3` จน `ssh cirros@172.24.4.122` และ `ping -c 4 8.8.8.8` (`0% packet loss`) ทำงานได้สำเร็จ

#### 4.2 สิ่งที่ไม่ได้อยู่ในขอบเขตและข้อจำกัดของสภาพแวดล้อม (Out of Scope & Limitations)
1. **การตั้งค่า External NAT (`br-ex`) เป็นแบบชั่วคราว (Runtime NAT):** เพื่อความปลอดภัยไม่แก้ไข Interface `ens3` ที่ใช้ SSH ของกลุ่ม การเปิดใช้งาน Floating IP (`172.24.4.122`) และการออกอินเทอร์เน็ต (`ping 8.8.8.8`) จึงใช้วิธีตั้ง IP `172.24.4.1/24` บน `br-ex` และกฎ `iptables` แบบ Runtime บน `controller01` ซึ่งค่าส่วนนี้จะไม่คงอยู่ถาวรหากเครื่อง `controller01` ถูกรีบูต (ต้องสั่งตั้งค่าใหม่หลังบูต)
2. **การใช้งานหน่วยเก็บข้อมูล Volume ของ Cinder (บทที่ ๑.2.17 – ๑.2.18 และ ๑.2.21):** โครงงานนี้มุ่งเน้นส่วนประกอบพื้นฐานเพื่อรันวีเอ็มผ่าน Local Storage ของ Compute Node จึงปิดบริการ Cinder (`enable_cinder: false`) และไม่ได้ทดสอบการสร้าง Boot Volume หรือการทำ Hot Plug ดิสก์เพิ่มเติม
3. **ความทนทานต่อความเสียหาย (Non-HA):** ระบบประกอบด้วย 1 Controller และ 1 Compute Node ตามขอบเขตของหัวข้อที่ 4 จึงไม่รองรับการทำ Failover หากโฮสต์ใดโฮสต์หนึ่งหยุดทำงาน

---

### 5. การแบ่งงานภายในกลุ่ม (Team Responsibilities)

กลุ่มที่ 25 (`grp25`) แบ่งบทบาทหน้าที่ความรับผิดชอบของสมาชิกทั้ง 3 คนอย่างชัดเจน ดังนี้:

1. **สมาชิกคนที่ 1 — [ชื่อ-นามสกุล] รหัสนักศึกษา [XXXXXXXXXX] (Infrastructure & Networking):**
   - ตรวจสอบโควตาทรัพยากร, สิทธิ์การใช้งาน และทดสอบความพร้อมของ Nested KVM (`vmx`, `/dev/kvm`, `kvm-ok`) บน Outer OpenStack
   - จัดเตรียมเครื่องเสมือน Ubuntu Server 24.04 LTS จำนวน 2 เครื่อง (`controller01` และ `compute01`) พร้อมจัดสรรและเม้าท์ดิสก์แยกขนาด 40 GB สำหรับ `/var/lib/docker`
   - ออกแบบโครงสร้างเครือข่าย (Management IP `192.168.1.160` และ `192.168.1.7`, การตั้งค่า `/etc/hosts`, SSH Key-based Authentication, การสร้างอินเทอร์เฟซ `dummy0` และการวิเคราะห์ค่า MTU `1450 -> 1400`)
   - จัดทำแผนภาพสถาปัตยกรรมและเรียบเรียงเนื้อหารายงานส่วนโครงสร้างพื้นฐาน
2. **สมาชิกคนที่ 2 — [ชื่อ-นามสกุล] รหัสนักศึกษา [XXXXXXXXXX] (OpenStack Installation & Deployment):**
   - จัดเตรียม Python Virtual Environment สำหรับ Kolla Ansible (`~/kolla-venv`) และ OpenStack CLI (`~/openstack-cli-venv`)
   - ปรับแต่งไฟล์ Ansible Inventory (`~/multinode`), ไฟล์ตั้งค่าหลัก (`/etc/kolla/globals.yml` สำหรับสถาปัตยกรรม Single-Controller Non-HA) และไฟล์ Neutron MTU Overrides
   - รันกระบวนการติดตั้ง `bootstrap-servers`, `prechecks`, `deploy` และ `post-deploy`
   - วิเคราะห์และแก้ไขปัญหาพอร์ต `3306` ชนกันระหว่าง MariaDB และ ProxySQL ด้วยการจัดการ `systemd` units จนการติดตั้งสำเร็จครบทุกบริการ
   - จัดทำไฟล์ตัวอย่าง Configuration ที่ตัดข้อมูลความลับออกแล้ว (`config/*.example`) ขึ้น GitHub และเรียบเรียงเนื้อหารายงานส่วนการติดตั้ง
3. **สมาชิกคนที่ 3 — [ชื่อ-นามสกุล] รหัสนักศึกษา [XXXXXXXXXX] (Testing, Administration & Documentation):**
   - ศึกษาคู่มือการใช้งานโอเพนสแตค (บทที่ ๑) และออกแบบตาราง Test Cases (`TC-01` ถึง `TC-16`) ให้สอดคล้องกับสถาปัตยกรรมของกลุ่ม
   - ตรวจสอบสถานะการทำงานของ Services, Hypervisor และ Network Agents ทั้งผ่าน OpenStack CLI และ Horizon Dashboard (ผ่าน SSH Tunnel)
   - ทดสอบและสาธิตการใช้งานระดับผู้ใช้: การจัดการ Image, Flavor, เครือข่ายเสมือน 2 วง (`cs223-private-net`, `cs223-net-2`), เครือข่ายภายนอก `ext-net` + Runtime NAT บน `br-ex`, เร้าเตอร์ `cs223-router`, Floating IP `172.24.4.122`, กลุ่มกฎไฟร์วอลล์ `SSH-ICMP`, คู่คีย์ `cs223-key`, การสร้าง VM 2 เครื่องบน `compute01` และการทดสอบ noVNC, `ssh` ข้าม Subnet และ `ping 8.8.8.8`
   - ทดสอบและสาธิตงานผู้ดูแลระบบตามแนวคิด RBAC `(User, Role, Scope)` Tuple: การสร้าง `Project-A`, การสร้างผู้ใช้ `A-user` พร้อมกำหนดบทบาท `member` และการปรับเปลี่ยนค่า Quota ของโปรเจกต์
   - รวบรวมและตรวจสอบความปลอดภัยของภาพหลักฐาน (ตัด Token/ซ่อนรหัสผ่าน ครบ 33 ไฟล์ใน `evidence/`), เรียบเรียงรูปเล่มรายงานฉบับสมบูรณ์ และประสานงานการผลิตวิดีโอสาธิต (Demo Video)

---

### 6. เอกสารอ้างอิง (References)

1. กษิดิศ ชาญเชี่ยว, *เอกสารประกอบการสอนและคู่มือปฏิบัติการ: การติดตั้งและการใช้งานระบบโอเพนสแตค (OpenStack Installation & User Tutorial v0.01)*, รายวิชา CS223 Virtualization Technology, เข้าถึงได้จาก: https://kasidit.github.io/OpenStack-Installation-Tutorial-0.01/ และ https://kasidit.github.io/OpenStack-Tutorial-0.01/
2. OpenStack Documentation (2026.1 Release), *Kolla Ansible Deployment Guide*, เข้าถึงได้จาก: https://docs.openstack.org/project-deploy-guide/kolla-ansible/2026.1/
3. OpenStack Keystone Documentation, *Role-Based Access Control (RBAC) and Default Roles*, เข้าถึงได้จาก: https://docs.openstack.org/keystone/latest/admin/service-api-protection.html
4. OpenStack Networking (Neutron) Documentation, *MTU Considerations and ML2 Configuration*, เข้าถึงได้จาก: https://docs.openstack.org/neutron/2026.1/admin/config-mtu.html
5. OpenStack Contributors, *python-openstackclient Command Reference*, เข้าถึงได้จาก: https://docs.openstack.org/python-openstackclient/latest/
6. Kevin Jackson et al. (2018), *OpenStack Cloud Computing Cookbook*, 4th Edition, Packt Publishing.
7. บันทึกการตั้งค่าและหลักฐานการทดสอบของกลุ่มที่ 25 (`grp25`): https://github.com/ronnakrit303/CS223-TermProject


---

## ส่วนที่ 3: สคริปต์ลำดับการอัดวิดีโอสาธิตฉบับสมบูรณ์ (Demo Video Script — ส่งวันที่ 8 ธ.ค. 2026)

> **เป้าหมาย:** ความยาวรวมประมาณ **10–15 นาที** อัปโหลดขึ้น YouTube / Facebook / Google Drive (ตั้งค่าสิทธิ์ให้ผู้มีลิงก์เข้าชมได้) แสดงทั้งการติดตั้ง การใช้งาน และการบริหารจัดการระบบของกลุ่มเอง โดยแบ่งหน้าที่พูดครบทั้ง 3 คน

### ฉากที่ 1: แนะนำโครงงานและสถาปัตยกรรม (คนที่ 1 — ~3 นาที)
* **สิ่งที่แสดงบนจอ:** หน้าปกรายชื่อสมาชิก + แผนภาพ Layered Architecture ใน [`docs/02-architecture.md`](02-architecture.md) + Terminal บน `controller01` และ `compute01`
* **ลำดับการสาธิตและบทพูด:**
  1. **แนะนำหัวข้อ:** กลุ่ม 25 เลือกหัวข้อที่ 4 ติดตั้งและบริหารจัดการระบบ OpenStack แบบ Multi-node 2 เครื่อง (1 Controller + 1 Compute) ด้วย Kolla Ansible บน Ubuntu Server 24.04.3 LTS (OpenStack 2026.1)
  2. **อธิบายสถาปัตยกรรม 3 ชั้น:**
     - **Outer Cloud:** ระบบคลาวด์ของอาจารย์ที่จัดสรร VM 2 เครื่องบนวงแลน `localnet1` (`192.168.1.0/24`, MTU `1450`)
     - **Inner Cloud:** `controller01` (`192.168.1.160`) ทำหน้าที่ Control + Network + Deployment และ `compute01` (`192.168.1.7`) ทำหน้าที่ Compute Node
  3. **โชว์คำสั่งพิสูจน์ Infrastructure:**
     - โชว์ `df -hT /var/lib/docker` (ดิสก์แยก 40 GB สำหรับ Docker Containers)
     - โชว์ `ip -br addr` (`ens3` MTU 1450 และ `dummy0` สำหรับ `br-ex`)
     - บน `compute01` โชว์ `ls -l /dev/kvm` และ `kvm-ok` ยืนยันการรองรับ Nested KVM

### ฉากที่ 2: การตั้งค่า Kolla Ansible และ Deployment (คนที่ 2 — ~3 นาที)
* **สิ่งที่แสดงบนจอ:** [`config/multinode.example`](../config/multinode.example), [`config/globals.example.yml`](../config/globals.example.yml), [`config/neutron/ml2_conf.ini.example`](../config/neutron/ml2_conf.ini.example) และ Terminal บน `controller01`
* **ลำดับการสาธิตและบทพูด:**
  1. **อธิบาย Virtual Environment:** แยก `~/kolla-venv` (Kolla Ansible `22.2.1.dev36`) ออกจาก `~/openstack-cli-venv` (`openstack 9.0.1`)
  2. **อธิบายไฟล์ `multinode` และ `globals.yml`:**
     - ชี้การแบ่งกลุ่ม `[control]` + `[network]` ที่ `controller01` และ `[compute]` ที่ `compute01`
     - อธิบายการตั้งค่า Single-Controller Non-HA: ใช้ `kolla_internal_vip_address: "192.168.1.160"` (หลีกเลี่ยงปัญหา VIP ถูกบล็อกโดย Port Security ชั้นนอก), ปิด `haproxy` / `keepalived` / `proxysql` และปิด `cinder` / `heat`
     - อธิบาย Neutron Override (`global_physnet_mtu = 1450`, `path_mtu = 1450`) เพื่อรองรับ VXLAN
  3. **โชว์ผลการ Deploy และ Containers:**
     - อธิบายลำดับ `bootstrap-servers` -> `prechecks` -> `deploy` -> `post-deploy` และโชว์บันทึก `PLAY RECAP` (`failed=0`, `DEPLOY EXIT STATUS: 0`)
     - รัน `sudo docker ps --format 'table {{.Names}}\t{{.Status}}'` โชว์สถานะ Containers (`Up` / `healthy`) บนทั้ง 2 เครื่อง

### ฉากที่ 3: การตรวจสอบ Services, Horizon และการสร้าง VM (คนที่ 3 — ~4–5 นาที)
* **สิ่งที่แสดงบนจอ:** Terminal บน `controller01`, Browser เปิด Horizon (`http://127.0.0.1:8080/`) และหน้าต่าง noVNC Console
* **ลำดับการสาธิตและบทพูด:**
  1. **ตรวจ Services & Compute Node Registration:** รัน [`scripts/verify-deployment.sh`](../scripts/verify-deployment.sh) (หรือ `openstack compute service list` + `openstack network agent list`) โชว์ว่า `nova-compute` บน `compute01` เป็น `enabled / up` และ Neutron Agents ครบ 5 ตัวเป็น `Alive :-)`
  2. **เข้าสู่ระบบ Horizon:** อธิบายการเปิด SSH Local Port Forwarding พอร์ต `8080` แล้วล็อกอินด้วยบัญชี `admin`
  3. **แสดงทรัพยากรตามตำราบทที่ ๑:**
     - เปิดดู Image `cirros-0.6.3` (`Active`) และ Flavor `cs223.tiny`
     - เปิดหน้า **Network Topology** โชว์เครือข่าย `ext-net` ↔ `cs223-router` ↔ 2 เครือข่าย VXLAN (`cs223-private-net` `10.10.10.0/24` และ `cs223-net-2` `10.20.20.0/24`, MTU 1400) พร้อมแสดง Floating IP (`172.24.4.122`)
     - เปิดหน้า **Security Groups** โชว์กลุ่มกฎ `SSH-ICMP` (เปิด `ALL ICMP` และ `SSH` พอร์ต 22)
  4. **สาธิตการสร้างและใช้งาน Test Instances, Routing & Floating IP:**
     - กด **Launch Instance** ให้เห็นขั้นตอนการตั้งค่า (ย้ำจุดสำคัญ: เลือก **`Create New Volume = No`** ตามภาพ ๑-21 ในตำราอาจารย์ เพราะปิด Cinder ไว้)
     - โชว์ `cs223-test-vm` (`10.10.10.117`, FIP `172.24.4.122`) และ `cs223-vm-2` (`10.20.20.78`) สถานะ `ACTIVE` รันอยู่บน `compute01`
     - เปิด **noVNC Console** (ผ่าน SSH Tunnel พอร์ต `6080` — ระวังไม่ให้เห็น Token ในคลิป) ล็อกอินเข้า CirrOS แล้วรัน `ip -4 addr show eth0` โชว์ IP `10.10.10.117/24` และ `mtu 1400`, ทดสอบ `ping -c 4 10.10.10.100` / `10.10.10.1`, `ssh cirros@10.20.20.78` ข้าม Router ไปหา `cs223-vm-2`, `ssh cirros@172.24.4.122` จาก `controller01` และ `ping -c 4 8.8.8.8` ออกอินเทอร์เน็ต (`0% packet loss`)
     - ทดลองกด **Pause / Unpause Instance** โชว์การควบคุมสถานะ VM

### ฉากที่ 4: งาน Admin (RBAC & Quota) และสรุปปัญหาที่พบ (คนที่ 3 ร่วมกับทีม — ~3 นาที)
* **สิ่งที่แสดงบนจอ:** เมนู **Identity** บน Horizon + Terminal CLI + สไลด์สรุปปัญหา
* **ลำดับการสาธิตและบทพูด:**
  1. **สาธิตงาน Admin (RBAC `(User, Role, Scope)` Tuple):**
     - เปิดเมนู **Identity > Projects** สร้าง `Project-A` และกด **Modify Quotas** ปรับค่า Compute/Network Quotas (เช่น Instances = 5, VCPUs = 4, RAM = 4096 MB, Ports = 200)
     - เปิดเมนู **Identity > Users** สร้าง `A-user` ผูกกับ `Project-A` ด้วยบทบาท `member` (โชว์ผล `openstack role assignment list` และ `openstack quota show Project-A` บน CLI คู่กัน)
     - ทดลอง **Sign Out จาก `admin` แล้ว Sign In ด้วย `A-user`** เพื่อพิสูจน์ว่า `A-user` เห็นเฉพาะ Project ของตัวเองและ **ไม่เห็นแท็บ `Admin`** ตามหลัก RBAC
  2. **สรุปปัญหาและการแก้ไข:**
     - เล่าปัญหา MariaDB ชนกับ ProxySQL ที่พอร์ต `3306` และการหยุด `kolla-proxysql-container.service` ผ่าน `systemd`
     - เล่าปัญหา `Destination Host Unreachable` ก่อนตั้ง IP บน `br-ex` และการตั้ง Runtime NAT (`172.24.4.1/24` + `iptables MASQUERADE`) เพื่อให้ออกเน็ตได้โดยไม่แตะ `ens3`
     - สรุปข้อจำกัดที่เหลือของ Lab (Host NAT เป็นแบบชั่วคราวใน RAM, Non-HA, ปิด Cinder) และกล่าวสรุปปิดการนำเสนอ
