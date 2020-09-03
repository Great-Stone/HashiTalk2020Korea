# HashiTalk: Korea - 2020

## Prerequisite

### Terraform
- Tested Version >= 0.13.1

### Naver cloud
- ACG 설정
    - 네이버 클라우드는 프로바이더에 2020년 8월 기준 Terraform으로 ACG 관리가 안됨
    - ACG의 Default 값에 사용되는 포트를 추가하거나 별도의 ACG를 추가하여야 함
- Autentication 환경 변수
    - NCLOUD_ACCESS_KEY
    - NCLOUD_SECRET_KEY

## Federation
- GCP : Primary
    - consul : http://{gcp-cn-server-External-IP}:8500
    - nomad : http://{gcp-cn-server-External-IP}:4646
- NCloud : Secondary
    - consul : http://{ncloud-cn-server-External-IP}:8500
    - nomad : http://{ncloud-cn-server-External-IP}:4646

## Deployment
1. API 서비스 배포 [Nomad / NCloud]
    - NCloud의 Nomad 콘솔 접속
    - 좌측 메뉴 `WORKLOAD` 하위의 `Jobs` 클릭
    - Jobs 화면의 우측에 `Run Job` 클릭
    - `jobs/count_api.hcl`의 내용 복사하여 붙여넣기
    - Plan / Apply
    - `cn-client` 에 실행된 api 서비스를 curl 로 확인
        ```bash
        $ curl http://{ncloud-cn-client-ip}:9001
        {"count":1,"hostname":"1ea9fd60801f"}
        ```
2. API 의 WAN IP 서비스 등록 [Consul / NCloud]
    - NCloud의 `cd-client`에 ssh 접속
    - consul `config-dir`로 지정한 위치(ex: /etc/consul.d)에 `consul_service/api.hcl` 내용을 참고하여 `api.hcl`파일 생성
        - Check 항목의 IP를 프로비저닝된 IP에 맞게 수정
        - lan address를 프로비저닝된 IP에 맞게 수정
        - wan address를 프로비저닝된 IP에 맞게 수정
    - `consul reload` 실행하여 디렉토리에 위한 설정 읽기
        ```bash
        $ consul reload
        Configuration reload triggered
        ```
    - NCloud의 Consul consol에 접속하여 추가된 `api`서비스 확인
    - Federation된 GCP의 Consul consol에서 확인되는 IP와 비교

3. Dashboard 서비스 배포 [Nomad / GCP]
    - GCP의 Nomad 콘솔 접속
    - 좌측 메뉴 `WORKLOAD` 하위의 `Jobs` 클릭
    - Jobs 화면의 우측에 `Run Job` 클릭
    - `jobs/count_dashiboard.hcl`의 내용 복사하여 붙여넣기
    - Plan / Apply

4. Consul 에서 서비스 확인 및 Dashiboard app 실행 확인
    - GCP의 Consul consol에 접속하여 추가된 `dashiboard`서비스 확인




