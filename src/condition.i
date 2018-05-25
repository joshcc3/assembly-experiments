%ifndef CONDITION_I
%define CONDITION_I

;; 
;; {
;;   int32_t* lock; 8 bytes
;;
;; } condition_t ;

;; void init_cond(int32_t* lock)
extern init_cond

;; void acquire_cond(condition_t* cond)
extern acquire_cond

;; void release_cond(condition_t* cond)
extern release_cond

;; void wait(condition_t* cond)
extern wait

;; int notify(condition_t* cond, int n)
extern notify

;; int notify_all(condition_t* condition_ptr)
extern notify_all

%endif
