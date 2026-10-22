set -x
flutter --version
# 프로젝트 생성 (현재 폴더에, iOS/Android만)
flutter create --org com.bts --project-name bizkeep --platforms ios,android --overwrite .
# 의존성 추가
flutter pub add flutter_riverpod drift sqlite3_flutter_libs path_provider path url_launcher shared_preferences uuid intl
flutter pub add --dev drift_dev build_runner
flutter pub get
ls -la
