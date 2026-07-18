# 05. CloudFront CDN 설계

## 개요
ALB 앞단에 CloudFront를 배치해 글로벌 엣지 캐싱과 HTTPS 종료를 제공한다. WAF는 이번 단계에서 제외했으며, 최종 정리 단계에서 짧게 연결해 검증 후 다시 분리할 예정이다.

## 아키텍처
```
Client (HTTPS)
  → CloudFront (Edge, PriceClass_100)
    → ALB (HTTP, custom origin)
      → EC2 ASG (nginx)
```

## 설계 결정

### 오리진: ALB 커스텀 오리진
S3 정적 호스팅 대신 ALB를 오리진으로 사용. 현재 프론트엔드가 별도 정적 자산이 아니라 EC2/ASG에서 서빙되는 동적 애플리케이션이기 때문. 추후 프론트엔드를 S3+CloudFront로 분리할 여지는 남겨둠.

### 오리진 프로토콜: HTTP-only (CloudFront ↔ ALB)
ALB에 ACM 인증서가 없어 오리진 구간은 HTTP로 유지. 클라이언트-엣지 구간(`viewer_protocol_policy = redirect-to-https`)만 CloudFront 기본 인증서로 암호화한다. 오리진 구간은 AWS 백본 내부 트래픽이라 실무에서도 흔한 절충안이지만, 프로덕션 전환 시 ACM 발급 후 `https-only`로 바꿔야 한다.

### 캐싱: CachingDisabled (managed)
퀴즈 생성 API 등 동적 콘텐츠라 캐싱하면 안 됨. 관리형 정책(`4135ea2d-6df8-44a3-9df3-4b5a84be39ad`) 사용. 정적 자산이 추가되면 별도 cache behavior(`/static/*`)로 분리해 `CachingOptimized` 적용 예정.

### Price Class: PriceClass_100
북미/유럽 엣지만 사용해 비용 절감. 실사용자는 호주 기준이라 레이턴시 최적은 아니지만, NAT Gateway 미사용과 같은 맥락의 비용 절제 원칙을 따름. 프로덕션이라면 `PriceClass_200` 이상으로 전환 필요.

### WAF 미연결
WAF는 AWS 프리티어 대상이 아니라 계정 상태와 무관하게 고정비(WebACL $5/월 + managed rule 그룹당 $1/월 × 3 + rate rule $1/월 ≈ $9/월)가 발생한다. 설계(managed rule 3종 + rate-based rule)는 완료했고, 최종 단계에서 짧게 apply → 검증 → destroy 하는 방식으로 비용을 관리한다.

### 데이터 레지던시 관련 예외
WAF WebACL(CLOUDFRONT 스코프)은 AWS 제약상 `us-east-1`에 리소스 메타데이터가 위치해야 한다. 실제 트래픽 처리와 오리진(ALB, EC2, Bedrock 추론)은 계속 `ap-southeast-2`/호주 크로스리전 프로필 내에 머문다. us-east-1에 존재하는 것은 WAF 설정 메타데이터뿐이며, 데이터 레지던시 원칙의 예외라기보다 AWS 글로벌 서비스의 구조적 제약에 가깝다.

## 비용

| 항목 | 예상 비용 | 비고 |
|---|---|---|
| CloudFront (PriceClass_100) | 프리티어 1TB/월 무료 | 포트폴리오 트래픽 수준에서 사실상 무료 |
| WAF (미연결) | $0 | 최종 단계에서만 임시 적용 |
| ALB (기존) | 변화 없음 | |

## 향후 개선
- ACM 인증서 발급 → 오리진 구간 HTTPS 전환
- 정적 자산 분리 시 cache behavior 추가
- WAF 연결 및 CloudWatch 대시보드 연동
- PriceClass 상향 검토
