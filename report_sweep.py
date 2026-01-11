#!/usr/bin/env python3
"""
Small parser for results. Was difficult to parse the logs because of ANSI artifacts
"""

import re
import glob
import os
from pathlib import Path
from collections import defaultdict

def parse_vunit_log(log_file):
    """Parse VUnit log file to extract test results"""
    config_name = Path(log_file).stem.replace('sweep_', '')
    
    passed = 0
    failed = 0
    total = 0
    failed_tests = []
    
    try:
        with open(log_file, 'r') as f:
            content = f.read()
        
        # Remove ANSI color codes for easier parsing
        # Pattern matches: ESC[...m or just [XXm
        ansi_escape = re.compile(r'\x1b\[[0-9;]*m|\[[0-9;]*m')
        clean_content = ansi_escape.sub('', content)
        
        # Find all individual test results
        # Pattern: "pass (P=X S=Y F=Z T=W) lib.tb_timer.test_name"
        test_pattern = r'(pass|fail)\s+\(P=\d+\s+S=\d+\s+F=\d+\s+T=\d+\)\s+lib\.tb_timer\.(\S+)'
        matches = re.findall(test_pattern, clean_content)
        
        for status, test_name in matches:
            if status == 'pass':
                passed += 1
            else:
                failed += 1
                failed_tests.append(test_name)
            total += 1
        
        # Alternative: look for summary line "pass X of Y" or "fail X of Y"
        if total == 0:
            summary_pattern = r'(pass|fail)\s+(\d+)\s+of\s+(\d+)'
            summary_match = re.search(summary_pattern, clean_content)
            if summary_match:
                status, count, total_tests = summary_match.groups()
                total = int(total_tests)
                if status == 'pass':
                    passed = total
                    failed = 0
                else:
                    failed = int(count)
                    passed = total - failed
        
        # Extract failed test names from summary section if we have failures
        if failed > 0 and not failed_tests:
            # Look in summary section for "fail lib.tb_timer.test_name"
            fail_pattern = r'fail\s+lib\.tb_timer\.(\S+)\s+'
            failed_tests = re.findall(fail_pattern, clean_content)
    
    except Exception as e:
        print(f"Warning: Error parsing {log_file}: {e}")
    
    return {
        'config': config_name,
        'passed': passed,
        'failed': failed,
        'total': total,
        'failed_tests': failed_tests,
        'status': 'PASS' if failed == 0 and total > 0 else 'FAIL' if failed > 0 else 'UNKNOWN'
    }

def extract_frequency_delay(config_name):
    """Extract frequency and delay from config name like '100MHz_1us'"""
    parts = config_name.split('_')
    freq = parts[0] if parts else 'Unknown'
    delay = parts[1] if len(parts) > 1 else 'Unknown'
    return freq, delay

def main():
    # Find all sweep logs in sweep_results directory or current directory
    sweep_dir = "sweep_logs"
    
    if os.path.exists(sweep_dir):
        log_pattern = os.path.join(sweep_dir, "sweep_*.log")
    else:
        log_pattern = "sweep_*.log"
    
    log_files = sorted(glob.glob(log_pattern))
    
    if not log_files:
        print("❌ No sweep log files found!")
        print(f"   Expected files matching: {log_pattern}")
        print("   Run: make sweep  (or ./run_sweep_all.sh)")
        return
    
    print("=" * 80)
    print("TIMER TEST SWEEP RESULTS SUMMARY")
    print("=" * 80)
    print(f"Found {len(log_files)} log file(s) in {os.path.dirname(log_pattern) or 'current directory'}")
    print()
    
    results = [parse_vunit_log(f) for f in log_files]
    
    # Summary table
    print("CONFIGURATION SUMMARY:")
    print("-" * 80)
    print(f"{'Configuration':<25} {'Passed':>8} {'Failed':>8} {'Total':>8} {'Status':>10}")
    print("-" * 80)
    
    total_passed = 0
    total_failed = 0
    total_tests = 0
    
    for r in results:
        status_symbol = "✓" if r['status'] == 'PASS' else "✗" if r['status'] == 'FAIL' else "?"
        print(f"{r['config']:<25} {r['passed']:>8} {r['failed']:>8} {r['total']:>8} {status_symbol:>5} {r['status']:>5}")
        total_passed += r['passed']
        total_failed += r['failed']
        total_tests += r['total']
    
    print("-" * 80)
    print(f"{'TOTAL':<25} {total_passed:>8} {total_failed:>8} {total_tests:>8}")
    print()
    
    # Overall result
    if total_failed == 0 and total_tests > 0:
        print("🎉 SUCCESS: ALL CONFIGURATIONS PASSED!")
        print(f"   ✓ {len(results)} configurations tested")
        print(f"   ✓ {total_tests} total tests executed")
        print(f"   ✓ 100% pass rate")
    elif total_tests == 0:
        print("⚠️  WARNING: No test results found in logs")
        print("   Check if logs contain VUnit output")
    else:
        print(f"❌ FAILURES DETECTED: {total_failed}/{total_tests} tests failed")
        print(f"   Pass rate: {100 * total_passed / total_tests:.1f}%")
    
    # Failed tests by config
    if total_failed > 0:
        print()
        print("=" * 80)
        print("FAILURES BY CONFIGURATION:")
        print("=" * 80)
        
        for r in results:
            if r['failed'] > 0:
                print(f"\n❌ {r['config']} ({r['failed']} failure{'' if r['failed'] == 1 else 's'}):")
                if r['failed_tests']:
                    for test in r['failed_tests']:
                        print(f"   • {test}")
                else:
                    print(f"   (Failed tests not identified)")
        
        # Failed tests aggregated
        print()
        print("=" * 80)
        print("FAILURES BY TEST:")
        print("=" * 80)
        
        test_failures = defaultdict(list)
        for r in results:
            for test in r['failed_tests']:
                test_failures[test].append(r['config'])
        
        if test_failures:
            for test in sorted(test_failures.keys()):
                configs = test_failures[test]
                print(f"\n❌ {test} ({len(configs)} config{'' if len(configs) == 1 else 's'}):")
                for config in configs:
                    freq, delay = extract_frequency_delay(config)
                    print(f"   • {config} ({freq}, {delay})")
        
            print()
            print("=" * 80)
            print("FAILURE ANALYSIS:")
            print("=" * 80)
            
            # Analyze by frequency
            freq_failures = defaultdict(int)
            delay_failures = defaultdict(int)
            
            for r in results:
                if r['failed'] > 0:
                    freq, delay = extract_frequency_delay(r['config'])
                    freq_failures[freq] += r['failed']
                    delay_failures[delay] += r['failed']
            
            if freq_failures:
                print("\nFailures by frequency:")
                for freq in sorted(freq_failures.keys()):
                    print(f"  • {freq}: {freq_failures[freq]} test(s) failed")
            
            if delay_failures:
                print("\nFailures by delay:")
                for delay in sorted(delay_failures.keys()):
                    print(f"  • {delay}: {delay_failures[delay]} test(s) failed")
            
            # Most problematic test
            if test_failures:
                most_problematic = max(test_failures.items(), key=lambda x: len(x[1]))
                print(f"\nMost problematic test:")
                print(f"  • {most_problematic[0]}: failed in {len(most_problematic[1])} configuration(s)")
    
    print()
    print("=" * 80)
    
    # Detailed logs info
    print("\nLog files analyzed:")
    for log_file in log_files:
        print(f"  • {log_file}")
    print()

if __name__ == "__main__":
    main()
