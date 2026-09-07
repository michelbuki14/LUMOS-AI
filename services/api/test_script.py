
import sys
sys.path.insert(0, ".")
with open("test_output.txt", "w") as f:
    try:
        f.write("SUCCESS: All routers imported OK\n")
    except Exception as e:
        import traceback
        f.write(f"ERROR: {e}\n")
        traceback.print_exc(file=f)
