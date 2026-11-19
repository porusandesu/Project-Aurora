import unittest

from tools.configure_release import configure_manifest


class ConfigureManifestTest(unittest.TestCase):
    def setUp(self):
        self.manifest = {
            "features": {
                "journey_planner": {
                    "enabled": True,
                    "rolloutPercentage": 100,
                    "minimumAppVersion": "1.0.0",
                    "killSwitch": False,
                }
            }
        }

    def test_canary_sets_local_cohort_and_minimum_version(self):
        result = configure_manifest(self.manifest, "1.2.0", "canary", 10)
        self.assertEqual(result["manifestVersion"], "1.2.0-canary")
        self.assertEqual(result["releaseChannel"], "canary")
        self.assertEqual(result["features"]["journey_planner"]["rolloutPercentage"], 10)
        self.assertEqual(result["features"]["journey_planner"]["minimumAppVersion"], "1.2.0")

    def test_stable_requires_full_rollout(self):
        with self.assertRaisesRegex(ValueError, "100 percent"):
            configure_manifest(self.manifest, "1.2.0", "stable", 50)

    def test_canary_requires_a_partial_cohort(self):
        with self.assertRaisesRegex(ValueError, "between 1 and 99"):
            configure_manifest(self.manifest, "1.2.0", "canary", 100)

    def test_version_must_be_semver_core(self):
        with self.assertRaisesRegex(ValueError, "MAJOR.MINOR.PATCH"):
            configure_manifest(self.manifest, "latest", "canary", 10)


if __name__ == "__main__":
    unittest.main()
