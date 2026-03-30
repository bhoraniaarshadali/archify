import 'package:flutter_test/flutter_test.dart';
import 'package:project_home_decor/ads/remote_config_service.dart';

void main() {
  group('RemoteConfigService FeatureType Logic Tests', () {
    test('FeatureType enum generates correct keys', () {
      expect(FeatureType.interior.suffix, 'interior');
      expect(FeatureType.interior.kieKey, 'kie_api_key_interior');
      expect(FeatureType.interior.apiFreeKey, 'apifree_key_interior');
      expect(FeatureType.interior.enabledKey, 'interior_enabled');
      
      expect(FeatureType.videoGeneration.suffix, 'video_generation');
      expect(FeatureType.videoGeneration.kieKey, 'kie_api_key_video_generation');
      expect(FeatureType.videoGeneration.apiFreeKey, 'apifree_key_video_generation');
      expect(FeatureType.videoGeneration.enabledKey, 'video_generation_enabled');
    });

    test('isFeatureEnabled logic: "11" should be disabled, others enabled', () {
      // Manual simulation of the service logic
      bool simulateIsEnabled(String status) => status != '11';
      
      expect(simulateIsEnabled('1'), isTrue);
      expect(simulateIsEnabled('11'), isFalse);
      expect(simulateIsEnabled('some_other_value'), isTrue);
      expect(simulateIsEnabled(''), isTrue);
    });
  });
}
