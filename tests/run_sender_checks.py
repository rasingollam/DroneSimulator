"""Run the exact Android sender against UDP fault injection and a real Godot host.

Requires a separately supplied org.json 20240303 JAR (test-only, not APK code).
"""
import argparse
from pathlib import Path
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parent.parent


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', required=True)
    parser.add_argument('--javac', required=True)
    parser.add_argument('--java', required=True)
    parser.add_argument('--json-jar', required=True)
    args = parser.parse_args()
    jar = str(Path(args.json_jar).resolve())
    with tempfile.TemporaryDirectory(prefix='vector-sender-') as temporary:
        output = Path(temporary)
        package = ROOT/'android-controller/src/com/vectorflight/controller'
        tests = ROOT/'android-controller/tests'
        def run(command):
            subprocess.run(list(map(str, command)), cwd=ROOT, check=True, timeout=40)
        run([args.javac,'-encoding','UTF-8','-cp',jar,'-d',output,
             tests/'stubs/android/os/SystemClock.java',package/'ControlState.java',package/'ControllerLink.java',
             tests/'ControllerRecoveryTest.java',tests/'ControllerLinkTest.java'])
        import os
        classpath = str(output)+os.pathsep+jar
        run([args.java,'-cp',classpath,'com.vectorflight.controller.ControllerRecoveryTest'])
        status, done = output/'host.json', output/'host.done'
        with (output/'host.log').open('w+',encoding='utf-8') as log:
            host = subprocess.Popen([args.godot,'--headless','--path',str(ROOT),'--script','tests/controller_host.gd',
                                     '--',str(status),str(done)],cwd=ROOT,stdout=log,stderr=subprocess.STDOUT)
            try:
                deadline = time.monotonic()+60
                while not status.exists() and host.poll() is None and time.monotonic()<deadline:
                    time.sleep(0.05)
                if not status.exists():
                    raise RuntimeError('Isolated Godot controller host did not start')
                run([args.java,'-cp',classpath,'com.vectorflight.controller.ControllerLinkTest',status,done])
            finally:
                done.touch()
                try:
                    host.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    host.terminate()
                    host.wait(timeout=5)
                log.seek(0)
                report=log.read()
                print(report)
                if host.returncode or 'SCRIPT ERROR:' in report or 'ERROR:' in report:
                    raise RuntimeError('Godot sender host failed')


if __name__ == '__main__':
    main()
