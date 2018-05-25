%ifndef ASSERT_I
%define ASSERT_I

;; void (void* func, char* message)
;; The arguments are assumed to be laid out on the stack
extern assert

;; void (int64_t return_code, void* message)
extern assert_false

;; void (int64_t return_code, void* message)
extern assert_false_with_return_code

%endif
