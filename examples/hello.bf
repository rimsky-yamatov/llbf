#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#define TAPE_SIZE 30000

static int label_counter = 0;
static int temp_counter = 0;

static int next_label(void) {
    return label_counter++;
}

static int next_temp(void) {
    return temp_counter++;
}

static void emit_inc_ptr(FILE *out) {
    int t0 = next_temp();
    int t1 = next_temp();
    fprintf(out, "  %%t%d = load i32, i32* %%ptr, align 4\n", t0);
    fprintf(out, "  %%t%d = add i32 %%t%d, 1\n", t1, t0);
    fprintf(out, "  store i32 %%t%d, i32* %%ptr, align 4\n", t1);
}

static void emit_dec_ptr(FILE *out) {
    int t0 = next_temp();
    int t1 = next_temp();
    fprintf(out, "  %%t%d = load i32, i32* %%ptr, align 4\n", t0);
    fprintf(out, "  %%t%d = sub i32 %%t%d, 1\n", t1, t0);
    fprintf(out, "  store i32 %%t%d, i32* %%ptr, align 4\n", t1);
}

static void emit_inc_cell(FILE *out) {
    int idx = next_temp();
    int ptr = next_temp();
    int cur = next_temp();
    int val = next_temp();
    fprintf(out, "  %%t%d = load i32, i32* %%ptr, align 4\n", idx);
    fprintf(out, "  %%t%d = getelementptr inbounds [%d x i8], [%d x i8]* @tape, i32 0, i32 %%t%d\n",
            ptr, TAPE_SIZE, TAPE_SIZE, idx);
    fprintf(out, "  %%t%d = load i8, i8* %%t%d, align 1\n", cur, ptr);
    fprintf(out, "  %%t%d = add i8 %%t%d, 1\n", val, cur);
    fprintf(out, "  store i8 %%t%d, i8* %%t%d, align 1\n", val, ptr);
}

static void emit_dec_cell(FILE *out) {
    int idx = next_temp();
    int ptr = next_temp();
    int cur = next_temp();
    int val = next_temp();
    fprintf(out, "  %%t%d = load i32, i32* %%ptr, align 4\n", idx);
    fprintf(out, "  %%t%d = getelementptr inbounds [%d x i8], [%d x i8]* @tape, i32 0, i32 %%t%d\n",
            ptr, TAPE_SIZE, TAPE_SIZE, idx);
    fprintf(out, "  %%t%d = load i8, i8* %%t%d, align 1\n", cur, ptr);
    fprintf(out, "  %%t%d = sub i8 %%t%d, 1\n", val, cur);
    fprintf(out, "  store i8 %%t%d, i8* %%t%d, align 1\n", val, ptr);
}

static void emit_output(FILE *out) {
    int idx = next_temp();
    int ptr = next_temp();
    int cur = next_temp();
    int v = next_temp();
    int ret = next_temp();
    fprintf(out, "  %%t%d = load i32, i32* %%ptr, align 4\n", idx);
    fprintf(out, "  %%t%d = getelementptr inbounds [%d x i8], [%d x i8]* @tape, i32 0, i32 %%t%d\n",
            ptr, TAPE_SIZE, TAPE_SIZE, idx);
    fprintf(out, "  %%t%d = load i8, i8* %%t%d, align 1\n", cur, ptr);
    fprintf(out, "  %%t%d = sext i8 %%t%d to i32\n", v, cur);
    fprintf(out, "  %%t%d = call i32 @putchar(i32 %%t%d)\n", ret, v);
}

static void emit_input(FILE *out) {
    int idx = next_temp();
    int ptr = next_temp();
    int in = next_temp();
    int ch = next_temp();
    fprintf(out, "  %%t%d = load i32, i32* %%ptr, align 4\n", idx);
    fprintf(out, "  %%t%d = getelementptr inbounds [%d x i8], [%d x i8]* @tape, i32 0, i32 %%t%d\n",
            ptr, TAPE_SIZE, TAPE_SIZE, idx);
    fprintf(out, "  %%t%d = call i32 @getchar()\n", in);
    fprintf(out, "  %%t%d = trunc i32 %%t%d to i8\n", ch, in);
    fprintf(out, "  store i8 %%t%d, i8* %%t%d, align 1\n", ch, ptr);
}

static void emit_program(FILE *out, const char *program, size_t *pos, size_t len) {
    while (*pos < len) {
        char c = program[*pos];
        (*pos)++;

        switch (c) {
            case '>':
                emit_inc_ptr(out);
                break;
            case '<':
                emit_dec_ptr(out);
                break;
            case '+':
                emit_inc_cell(out);
                break;
            case '-':
                emit_dec_cell(out);
                break;
            case '.':
                emit_output(out);
                break;
            case ',':
                emit_input(out);
                break;
            case '[': {
                int id = next_label();
                fprintf(out, "  br label %%loop_cond%d\n\n", id);
                fprintf(out, "loop_cond%d:\n", id);

                int idx = next_temp();
                int ptr = next_temp();
                int cur = next_temp();
                int cmp = next_temp();
                fprintf(out, "  %%t%d = load i32, i32* %%ptr, align 4\n", idx);
                fprintf(out, "  %%t%d = getelementptr inbounds [%d x i8], [%d x i8]* @tape, i32 0, i32 %%t%d\n",
                        ptr, TAPE_SIZE, TAPE_SIZE, idx);
                fprintf(out, "  %%t%d = load i8, i8* %%t%d, align 1\n", cur, ptr);
                fprintf(out, "  %%t%d = icmp ne i8 %%t%d, 0\n", cmp, cur);
                fprintf(out, "  br i1 %%t%d, label %%loop_body%d, label %%loop_end%d\n\n", cmp, id, id);

                fprintf(out, "loop_body%d:\n", id);
                emit_program(out, program, pos, len);
                fprintf(out, "  br label %%loop_cond%d\n\n", id);
                fprintf(out, "loop_end%d:\n", id);
                break;
            }
            case ']':
                return;
            default:
                break;
        }
    }
}

static void emit_header(FILE *out, const char *modname) {
    fprintf(out, "; ModuleID = '%s'\n", modname);
    fprintf(out, "declare i32 @putchar(i32)\n");
    fprintf(out, "declare i32 @getchar()\n\n");
    fprintf(out, "@tape = global [%d x i8] zeroinitializer, align 1\n\n", TAPE_SIZE);
    fprintf(out, "define i32 @main() {\n");
    fprintf(out, "entry:\n");
    fprintf(out, "  %%ptr = alloca i32, align 4\n");
    fprintf(out, "  store i32 0, i32* %%ptr, align 4\n");
}

static void emit_footer(FILE *out) {
    fprintf(out, "  ret i32 0\n");
    fprintf(out, "}\n");
}

static char *read_entire_file(const char *path, size_t *out_size) {
    FILE *fp = fopen(path, "rb");
    if (!fp) {
        return NULL;
    }

    if (fseek(fp, 0, SEEK_END) != 0) {
        fclose(fp);
        return NULL;
    }

    long size = ftell(fp);
    if (size < 0) {
        fclose(fp);
        return NULL;
    }

    if (fseek(fp, 0, SEEK_SET) != 0) {
        fclose(fp);
        return NULL;
    }

    char *buf = (char *)malloc((size_t)size + 1U);
    if (!buf) {
        fclose(fp);
        return NULL;
    }

    size_t read_count = fread(buf, 1, (size_t)size, fp);
    fclose(fp);
    if (read_count != (size_t)size) {
        free(buf);
        return NULL;
    }

    buf[size] = '\0';
    if (out_size) {
        *out_size = (size_t)size;
    }
    return buf;
}

static void print_usage(const char *prog) {
    fprintf(stderr, "Usage: %s input.bf -o output.exe\n", prog);
    fprintf(stderr, "       %s input.bf -o output.ll --emit-ll\n", prog);
    fprintf(stderr, "       %s --emit-ll input.bf -o output.ll\n", prog);
}

static void build_ll_path(const char *output, int emit_ll_only, char *ll_path, size_t ll_path_size) {
    if (emit_ll_only) {
        snprintf(ll_path, ll_path_size, "%s", output);
        return;
    }

    snprintf(ll_path, ll_path_size, "%s.ll", output);
}

int main(int argc, char **argv) {
    if (argc < 2) {
        print_usage(argv[0]);
        return 1;
    }

    const char *input_path = NULL;
    const char *output_path = NULL;
    int emit_ll_only = 0;

    for (int i = 1; i < argc; ++i) {
        if (strcmp(argv[i], "--emit-ll") == 0) {
            emit_ll_only = 1;
        } else if (strcmp(argv[i], "-o") == 0) {
            if (i + 1 >= argc) {
                print_usage(argv[0]);
                return 1;
            }
            output_path = argv[++i];
        } else if (argv[i][0] == '-') {
            fprintf(stderr, "Unknown option: %s\n", argv[i]);
            print_usage(argv[0]);
            return 1;
        } else if (!input_path) {
            input_path = argv[i];
        } else {
            fprintf(stderr, "Unexpected argument: %s\n", argv[i]);
            print_usage(argv[0]);
            return 1;
        }
    }

    if (!input_path || !output_path) {
        print_usage(argv[0]);
        return 1;
    }

    char ll_path[2048];
    build_ll_path(output_path, emit_ll_only, ll_path, sizeof(ll_path));

    size_t source_size = 0;
    char *program = read_entire_file(input_path, &source_size);
    if (!program) {
        perror("Failed to read input file");
        return 1;
    }

    FILE *ll_out = fopen(ll_path, "w");
    if (!ll_out) {
        perror("Failed to open LLVM IR output");
        free(program);
        return 1;
    }

    size_t pos = 0;
    emit_header(ll_out, input_path);
    emit_program(ll_out, program, &pos, source_size);
    emit_footer(ll_out);
    fclose(ll_out);
    free(program);

    if (emit_ll_only) {
        printf("Generated LLVM IR: %s\n", ll_path);
        return 0;
    }

    char command[4096];
    snprintf(command, sizeof(command), "clang \"%s\" -O2 -o \"%s\"", ll_path, output_path);
    printf("Running: %s\n", command);
    int rc = system(command);
    if (rc != 0) {
        fprintf(stderr, "clang failed to build %s\n", output_path);
        return rc;
    }

    remove(ll_path);
    printf("Built executable: %s\n", output_path);
    return 0;
}
