#!/bin/sh

{
# 웹서버 설치
sudo dnf install -y nginx
# 웹서버 실행
sudo systemctl enable --now nginx

# 드라이브 식별자 설정
DRIVE=/dev/xvdh
MOUNT_POINT="/hlab"

# 시작 시간 설정
start_time=$(date +%s)

# EBS 볼륨이 연결될 때까지 대기
while [ ! -e $DRIVE ]
do
  echo "Waiting for EBS volume to attach"
  sleep 10
  
  # 현재 시간을 계산
  current_time=$(date +%s)
  
  # 경과 시간 계산
  elapsed_time=$((current_time - start_time))
  
  # 5분(300초)이 넘었는지 검사
  if [ $elapsed_time -ge 300 ]; then
    echo "Failed to attach EBS volume within 5 min."
    exit 1
  fi
done

# parted를 사용하여 GPT 레이블 생성
sudo parted $DRIVE --script mklabel gpt

# 파티션 생성 (파티션 타입: xfs, 전체 드라이브 사용)
sudo parted $DRIVE --script unit TB mkpart primary xfs 0 100%

# 파티션 포멧
sudo mkfs.xfs ${DRIVE}1

# 마운트 포인트 생성
sudo mkdir -p $MOUNT_POINT

# 파일 시스템 마운트
sudo mount ${DRIVE}1 $MOUNT_POINT

# 권한 부여
sudo chmod 777 $MOUNT_POINT

# UUID를 찾기
UUID=$(sudo blkid -s UUID -o value ${DRIVE}1)
if [ -z "$UUID" ]; then
    echo "Error: UUID not found for device ${DRIVE}1."
    exit 1
fi

# /etc/fstab에 마운트 정보가 이미 있는지 확인
if grep -qs "$UUID" /etc/fstab; then
    echo "A mount entry for this UUID already exists in /etc/fstab."
else
    # /etc/fstab에 새로운 마운트 포인트 추가
    echo "UUID=$UUID $MOUNT_POINT xfs defaults 0 0" | sudo tee -a /etc/fstab > /dev/null
    echo "New mount entry added to /etc/fstab."
fi

# 마운트 확인
sudo mount -a
if mountpoint -q $MOUNT_POINT; then
    echo "Mount successful."
else
    echo "Mount failed."
fi

# lauch.sh 로그 기록
} >> /var/log/launch_sh.log 2>&1